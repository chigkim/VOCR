from typing import Tuple, Union
from rectangle import Rectangle
import numpy as np

class Classifier:
    def __init__(self, model, img_width, img_height) -> None:
        """
        Initializes the classifier with a model and image dimensions.

        Args:
            model (___): classifier model
            img_width (int): width of image
            img_height (int): height of image
        """
        self.model = model
        self.img_width = img_width
        self.img_height = img_height
    
    def classify_n(self, img, rects: list[Rectangle]) -> list[Tuple[str, float]]:
        """
        Classifies more than one rectangle in image.

        Args:
            img (np.ndarray): image
            rects (list[Rectangle]): list of rectangles to classify

        Returns:
            list[Tuple[str, float]]: list of tuples of label and confidence
        """
        num_rects = len(rects)


        return []

    def classify_one(self, img, rect: Rectangle) -> Tuple[str, float]:
        """
        Classifies a single rectangle.

        Args:
            img (np.ndarray): image
            rect (Rectangle): rectangle to classify

        Returns:
            Tuple[str, float]: tuple of label and confidence
        """

        return ("Test", 1)