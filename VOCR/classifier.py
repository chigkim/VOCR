from typing import Tuple, Union
import numpy as np

class Classifier:
    def __init__(self, model, img_width, img_height) -> None:
        """
        Initializes the classifier with a model and image dimensions.
        """
        self.model = model
        self.img_width = img_width
        self.img_height = img_height
    
    def classify_n(self, img, rects):
        """
        Classifies more than one rectangle in image.
        """
        num_rects = len(rects)

    def classify_one(self, img, rect):
        """
        Classifies a single rectangle.
        """