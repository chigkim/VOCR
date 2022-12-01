from typing import Tuple, Union
import cv2
import numpy as np
import scipy


EPSILON = 0.5
HOUGH_CIRCLE_PARAMS = {"minDist":30, 
                        "param1":40, 
                        "param2":100, #smaller value-> more false circles
                        "minRadius":5,
                        "maxRadius":40
}
MIN_PERCENT_OF_IMAGE = 0.1
MAX_PERCENT_OF_IMAGE = 15
NO_CONFIDENCE = 0
FULL_CONFIDENCE = 1

class Rectangle:
    def __init__(self, label, confidence, topx, topy, width, height) -> None:
        self._topx = topx
        self._topy = topy
        self._width = width
        self._height = height
        self.label = label
        self.confidence = confidence
    
    def get_values(self) -> Tuple[float, float, float, float]:
        return (self._topx, self._topy, self._width, self._height)
    
    def set_label(self, label) -> None:
        self._label = label
    
    def compare_labels(self, other) -> Tuple[Union[str, None], float]:
        """
        Returns tuple of better label and corresponding confidence
        """
        # TODO: confidence logic
        if self.confidence > other.confidence:
            return (self.label, self.confidence)
        else:
            return (other.label, other.confidence)
    
    def normalize(self, img_width, img_height) -> None:
        # let newTopLeft = CGPoint(x: box.minX, y: imgSize.height-box.maxY)
        # let newRect = CGRect(x: newTopLeft.x, y: newTopLeft.y, width: box.width, height: box.height)
        # let normalizedBox = VNNormalizedRectForImageRect(newRect, Int(imgSize.width), Int(imgSize.height))
        # return normalizedBox
        new_top_x = self._topx / int(img_width)
        new_top_y = (img_height - self._topy - self._height) / int(img_height)
        new_width = self._width / int(img_width)
        new_height = self._height / int(img_height)
        self._topx = new_top_x
        self._topy = new_top_y
        self._width = new_width
        self._height = new_height

def _overlap_in_one_dim(start1, start2, length1, length2, min_dist_between):
    """
    Checks if there is an overlap within this dimension

    Args:
        start1 (int): the starting value of the first line
        start2 (int): the starting value of the second second
        length1 (int): the length of the first line
        length2 (int): the length of the second line
        min_dist_between (int): the minimum distance between two rectangles

    Returns:
        bool: returns whether there is an overlap between these two lines (in one dimension)
    """
    ret_value = False
    second_start = (2, start2)
    if start2 < start1:
        second_start = (1, start1)
    first_end = (1, start1 + length1)
    if start2 + length2 < start1 + length1:
        first_end = (2, start2 + length2)
    if first_end[0] == second_start[0]:
        ret_value = True
    if second_start[1] - first_end[1] < min_dist_between:
        ret_value = True
    return ret_value
    
def _check_rectangle_overlap(rect1, rect2, min_dist_between):
    """
    Checks if two rectangles overlap (or are within epsilon of each other)

    Args:
        rect1 (tuple(x, y, w, h)): first rectangle
        rect2 (tuple(x, y, w, h)): second rectangle
        min_dist_between (int): min distance between rectangles next to each other

    Returns:
        bool: Whether these rectangles overlap
    """
    x1, y1, w1, h1 = rect1.get_values()
    x2, y2, w2, h2 = rect2.get_values()
    return _overlap_in_one_dim(x1, x2, w1, w2, min_dist_between) \
        and _overlap_in_one_dim(y1, y2, h1, h2, min_dist_between)

def _get_combined_rect(rect1, rect2):
    """
    Create and return a new rectangle that is a combination of the two rectangles
    The new rectangle covers any value either of the two other rectangles cover

    Args:
        rect1 (tuple(x, y, w, h)): first rectangle
        rect2 (tuple(x, y, w, h)): second rectangle

    Returns:
        tuple(x, y, w, h): new rectangle which is outer combination of parameter rectangles
    """
    x1, y1, w1, h1 = rect1.get_values()
    x2, y2, w2, h2 = rect2.get_values()
    low_x = min(x1, x2)
    high_x = max(x1+w1, x2+w2)
    low_y = min(y1, y2)
    high_y = max(y1+h1, y2+h2)
    new_label, new_confidence = rect1.compare_labels(rect2)
    new_rect = Rectangle(new_label, new_confidence, low_x, low_y, high_x - low_x, high_y - low_y)
    return new_rect

def _prune_rectangles(rectangles, min_size, max_size):
    """
    Prune rectangles outside of desired size

    Args:
        rectangles (List(Tuple(x, y, w, h))): list of rectangles
        min_size (float): min area of the rectangle
        max_size (float): max area of the rectangle

    Returns:
        List(Tuple(x, y, w, h)): list of rectangles not including the large or small ones
    """
    small_rectangles = []
    for rect1 in rectangles:
        _, _, w1, h1 = rect1.get_values()
        if w1*h1 >= max_size:
            continue
        if w1 <= min_size or h1 <= min_size:
            continue
        small_rectangles.append(rect1)
    return small_rectangles

def get_rects_for_image(img, width, height, text_rects, text_labels):
    # print('rects', text_rects)
    # print('labels', text_labels)

    # convert text boxes and labels to Rectangles
    text_rectangles = []
    for coords, label in zip(text_rects, text_labels):
        # print(x, y, w, h)
        # scaled_x, scaled_y, scaled_w, scaled_h = width*x, height*y, width*w, height*h
        # print(scaled_x, scaled_y, scaled_w, scaled_h)
        text_rectangles.append(Rectangle(label, FULL_CONFIDENCE, *coords))

    # scale image and convert to grayscale
    min_dist_between = EPSILON*(min(height, width)/100)
    img = np.uint8(img)
    img = np.array(img).reshape((height, width, 4))

    gray = cv2.cvtColor(img, cv2.COLOR_RGBA2GRAY)

    # setting threshold of gray image
    _, threshold = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)

    # Find contours
    (contours,_) = cv2.findContours(threshold, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    rectangles = []
    for contour in contours:
        tup: tuple = cv2.boundingRect(contour)
        rectangles.append(Rectangle(None, NO_CONFIDENCE, *tup)) # rectangle with no label and 0% confidence
        
    total_image_size = np.prod(gray.shape)
    
    # Prune out large rectangles
    rectangles = _prune_rectangles(rectangles, 0, MAX_PERCENT_OF_IMAGE*total_image_size/100)
    
    def combine_rectangles(rectangles):
        still_combining = True
        while still_combining:
            combined_rectangles = []
            still_combining = False
            removed_idx = set()
            for i, rect1 in enumerate(rectangles):
                if i in removed_idx:
                    continue
                expanding_rect = rect1
                for j in range(i+1, len(rectangles)):
                    assert(j > i)
                    rect2 = rectangles[j]
                    if j in removed_idx:
                        continue
                    if _check_rectangle_overlap(expanding_rect, rect2, min_dist_between):
                        expanding_rect = _get_combined_rect(expanding_rect, rect2)
                        still_combining = True  
                        removed_idx.add(j)
                combined_rectangles.append(expanding_rect)
            rectangles = combined_rectangles
        return rectangles
    
    combined_rectangles = combine_rectangles(rectangles)

    # Prune out large rectangles again, but this time they must be 2 times as large
    final_rectangles = _prune_rectangles(combined_rectangles, min_dist_between, MAX_PERCENT_OF_IMAGE*total_image_size*2/100)

    # Assert that no rectangles overlap
    for rect1 in final_rectangles:
        for rect2 in final_rectangles:
            if rect1 != rect2:
                assert (not _check_rectangle_overlap(rect1, rect2, min_dist_between)), "failed: " + str(rect1) + str(rect2)

    # Convert contour rects to normalized rects
    for rect in final_rectangles:
        rect.normalize(width, height)

    for rect in final_rectangles:
        print('rect', rect.get_values())
    
    for rect in text_rectangles:
        print('rect', rect.get_values())

    # Prepare return
    final_tuples = [rect.get_values() for rect in final_rectangles]
    final_tuples.append((0, 0, width, height))
    return final_tuples

