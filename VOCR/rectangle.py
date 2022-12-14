from typing import Tuple, Union

class Rectangle:
    def __init__(self, label, confidence, topx, topy, width, height) -> None:
        self._topx = topx
        self._topy = topy
        self._width = width
        self._height = height
        self.label = label
        self.confidence = confidence

    def __str__(self) -> str:
        return f"Rectangle({self._topx}, {self._topy}, {self._width}, {self._height}, {self.label}, {self.confidence})"
    
    def get_values(self) -> Tuple[float, float, float, float]:
        return (self._topx, self._topy, self._width, self._height)

    def get_swift_rectangle(self) -> Tuple[float, float, float, float, int]:
        return (self._topx, self._topy, self._width, self._height, self.label)
    
    def area(self) -> float:
        return self._width * self._height
    
    def set_label(self, label) -> None:
        self.label = label

    def set_confidence(self, confidence) -> None:
        self.confidence = confidence
    
    def compare_labels(self, other) -> Tuple[Union[int, None], float]:
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

    def unnormalize(self, img_width, img_height) -> None:
        new_height = int(self._height * img_height)
        new_width = int(self._width * img_width)
        new_topx = int(self._topx * img_width)
        new_topy = int((1 - (self._topy + self._height)) * img_height)
        self._height = new_height
        self._width = new_width
        self._topx = new_topx
        self._topy = new_topy
