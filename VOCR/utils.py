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


#TODO: Make a rectangle class

def _overlap_in_one_dim(start1, start2, length1, length2, min_dist_between, first_time=True):
    """
    Checks if there is an overlap within this dimension

    Args:
        start1 (int): the starting value of the first line
        start2 (int): the starting value of the second second
        length1 (int): the length of the first line
        length2 (int): the length of the second line
        first_time (bool, optional): Whether this is the first call to the function. Defaults to True.

    Returns:
        bool: returns whether there is an overlap between these two lines (in one dimension)
    """
    if start1 <= start2 and start1 + length1 >= start2:
        return True
    if start1 <= start2 + length2 and start1 + length1 >= start2 + length2:
        return True
    if start1 <= start2 and start1 + length1 >= start2 + length2:
        return True
    diff = start2 - (start1 + length1)
    if diff >= 0 and diff < min_dist_between:
        return True
    if first_time:
        return _overlap_in_one_dim(start2, start1, length2, length1, min_dist_between, False)
    return False
    
    
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
    x1, y1, w1, h1 = rect1
    x2, y2, w2, h2 = rect2
    return _overlap_in_one_dim(x1, x2, w1, w2, min_dist_between) and _overlap_in_one_dim(y1, y2, h1, h2, min_dist_between)

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
    x1, y1, w1, h1 = rect1
    x2, y2, w2, h2 = rect2
    low_x = min(x1, x2)
    high_x = max(x1+w1, x2+w2)
    low_y = min(y1, y2)
    high_y = max(y1+h1, y2+h2)
    new_rect = (low_x, low_y, high_x - low_x, high_y - low_y)
    return new_rect

def prune_large_rectangles(rectangles, min_size, max_size):
    """
    Prune large rectangles

    Args:
        rectangles (List(Tuple(x, y, w, h))): list of rectangles
        min_size (float): min area of the rectangle
        max_size (float): max area of the rectangle

    Returns:
        List(Tuple(x, y, w, h)): list of rectangles not including the large ones
    """
    small_rectangles = []
    for rect1 in rectangles:
        _, _, w1, h1 = rect1
        if w1*h1 >= max_size:
            continue
        if w1 <= min_size or h1 <= min_size:
            continue
        small_rectangles.append(rect1)
    return small_rectangles

def get_rects_for_image(img, width, height):
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
        (x,y,w,h) = cv2.boundingRect(contour)
        rectangles.append((x, y, w, h))
        
    total_image_size = np.prod(gray.shape)
    
    # Prune out large rectangles
    rectangles = prune_large_rectangles(rectangles, 0, MAX_PERCENT_OF_IMAGE*total_image_size/100)
    
#     # docstring of HoughCircles: HoughCircles(image, method, dp, minDist[, circles[, param1[, param2[, minRadius[, maxRadius]]]]]) -> circles
#     circles = cv2.HoughCircles(gray, cv2.HOUGH_GRADIENT, 1, HOUGH_CIRCLE_PARAMS["minDist"], HOUGH_CIRCLE_PARAMS["param1"], HOUGH_CIRCLE_PARAMS["param2"], HOUGH_CIRCLE_PARAMS["minRadius"], HOUGH_CIRCLE_PARAMS["maxRadius"])

#     # Add bounding boxes for circles
#     if circles is not None:
#         circles = np.uint16(np.around(circles))
#         for circle in circles[0,:]:
#             mid_x, mid_y, radius = circle
#             rectangles.append((mid_x - radius, mid_y - radius, 2*radius, 2*radius))
                    
    # Combine overlapping (and near) rectangles
    still_combining = True
    while still_combining:
        combined_rectangles = []
        still_combining = False
        combined_rectangles = []
        while len(rectangles) > 0:
            current_expanding_rectangle = rectangles.pop()
            intersection = True
            while intersection:
                intersection = False
                updated_rectangles = []
                for rect in rectangles:
                    if _check_rectangle_overlap(current_expanding_rectangle, rect, min_dist_between):
                        current_expanding_rectangle = _get_combined_rect(current_expanding_rectangle, rect)
                        intersection = True
                        still_combining = True
                    else:
                        updated_rectangles.append(rect)
                rectangles = updated_rectangles
            combined_rectangles.append(list(current_expanding_rectangle))
        rectangles = combined_rectangles

    # Prune out large rectangles again, but this time they must be 2 times as large
    final_rectangles = prune_large_rectangles(combined_rectangles, min_dist_between, MAX_PERCENT_OF_IMAGE*total_image_size*2/100)
    
    # Assert that no rectangles overlap
    for rect1 in final_rectangles:
        for rect2 in final_rectangles:
            if rect1 != rect2:
                assert (not _check_rectangle_overlap(rect1, rect2, min_dist_between)), "failed: " + str(rect1) + str(rect2)

    final_rectangles.append((0, 0, width, height))
    return final_rectangles

