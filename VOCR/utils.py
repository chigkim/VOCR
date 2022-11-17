import cv2
import numpy as np
import scipy

def _overlap_in_dim(start1, start2, length1, length2, epsilon, first_time=True):
    if start1 < start2 and start1 + length1 > start2:
        return True
    if start1 < start2 + length2 and start1 + length1 > start2 + length2:
        return True
    diff = start2 - (start1 + length1)
    if diff > 0 and diff < epsilon:
        return True
    if first_time:
        return _overlap_in_dim(start2, start1, length2, length1, epsilon, False)
    return False
    
    
def _check_rectangle_overlap(rect1, rect2):
    epsilon = 5
    x1, y1, w1, h1 = rect1
    x2, y2, w2, h2 = rect2
    return _overlap_in_dim(x1, x2, w1, w2, epsilon) and _overlap_in_dim(y1, y2, h1, h2, epsilon)

def _get_combined_rect(rect1, rect2):
    x1, y1, w1, h1 = rect1
    x2, y2, w2, h2 = rect2
    low_x = min(x1, x2)
    high_x = max(x1+w1, x2+w2)
    low_y = min(y1, y2)
    high_y = max(y1+h1, y2+h2)
    new_rect = (low_x, low_y, high_x - low_x, high_y - low_y)
    return new_rect

def get_rects_for_image(abs_direct):
    img = cv2.imread(abs_direct)

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    binary = cv2.bitwise_not(gray)

    # setting threshold of gray image
    _, threshold = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY+cv2.THRESH_OTSU)
    (contours,_) = cv2.findContours(threshold, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    rectangles = []
    for contour in contours:
        (x,y,w,h) = cv2.boundingRect(contour)
        rectangles.append((x, y, w, h))
        
    total_image_size = np.prod(gray.shape)
    max_percent_of_image = 15
    
    minDist = 10
    param1 = 50
    param2 = 40 #smaller value-> more false circles
    minRadius = 5
    maxRadius = 30 #10
    # docstring of HoughCircles: HoughCircles(image, method, dp, minDist[, circles[, param1[, param2[, minRadius[, maxRadius]]]]]) -> circles
    circles = cv2.HoughCircles(gray, cv2.HOUGH_GRADIENT, 1, minDist, param1=param1, param2=param2, minRadius=minRadius, maxRadius=maxRadius)
    

        
    small_rectangles = []
    for rect1 in rectangles:
        x1, y1, w1, h1 = rect1
        if w1*h1 >= max_percent_of_image*total_image_size/100:
            continue
        small_rectangles.append(rect1)
    rectangles = small_rectangles
    
    if circles is not None:
        circles = np.uint16(np.around(circles))
        for circle in circles[0,:]:
            mid_x, mid_y, radius = circle
            rectangles.append((mid_x - radius, mid_y - radius, 2*radius, 2*radius))
        
    final_rectangles = []
    while len(rectangles) > 0:
        current_expanding_rectangle = rectangles.pop()
        intersection = True
        while intersection:
            intersection = False
            updated_rectangles = []
            for rect in rectangles:
                if _check_rectangle_overlap(current_expanding_rectangle, rect):
                    current_expanding_rectangle = _get_combined_rect(current_expanding_rectangle, rect)
                    intersection = True
                else:
                    updated_rectangles.append(rect)
            rectangles = updated_rectangles
        final_rectangles.append(list(current_expanding_rectangle))
        
    return final_rectangles

