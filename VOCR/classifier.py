from typing import Tuple, Union
from rectangle import Rectangle
import tensorflow as tf
from tensorflow.keras.models import load_model
import os 
import numpy as np
# label_map = {0: 'arrow', 1: 'button', 2: 'dropdown', 3: 'icon', 4: 'knob', 5: 'light', 6: 'meter',
#  7: 'multiple elements', 8: 'multiple knobs', 9: 'needle', 10: 'non-interactive',
#  11: 'radio button', 12: 'slider', 13: 'switch', 14: 'unknown'}

class Classifier:

	def __init__(self, img, width, height, model_loc='/VOCR/model.h5'):
		'''
		:param img: a numpy array of the image (height, width, channels) to be classified.
		For example, (224, 224, 3)
		:param width: a width value in pixels (NOT inches or other arbitrary metrics)
		:param height: a height value in pixels (NOT inches or other arbitrary metrics)
		:param model_loc: the location of the model in .h5 format to be loaded
		'''
		self.img = img
		self.w = width
		self.h = height
		print(os.getcwd())
		self.model = load_model(os.getcwd() + model_loc)

	def classify_n(self, box_value, img_size=(224,224), output_type='int'):
		'''

		:param box_value: the box value needs to be a list of tuples (even if it is a list of
		a single tuple) where each tuple is (top x, top y, width, height)
		:param img_size: tuple, by default it is 224 by 224, but it could be modified if the model is
		also modified
		:param output_type: string, by default "int", culd be "str" to output label name
		:return:
		'''
		classification = []
		for topx, topy, b_width, b_height in box_value:
			img_section = self.img[topy:topy + b_height, topx:topx + b_width, :]
			img_scaled = tf.image.resize(img_section, img_size)
			model_pred = self.model.predict(img_scaled[np.newaxis, :, :, :])
			classification.append(np.argmax(model_pred))

		return classification
		# if output_type == 'int':
		# 	return classification
		# else:
		# 	return [label_map[c] for c in classification]

# class Classifier:
#     def __init__(self, model, img_width, img_height) -> None:
#         """
#         Initializes the classifier with a model and image dimensions.
#
#         Args:
#             model (___): classifier model
#             img_width (int): width of image
#             img_height (int): height of image
#         """
#         self.model = model
#         self.img_width = img_width
#         self.img_height = img_height
#
#     def classify_n(self, img, rects: list[Rectangle]) -> list[Tuple[str, float]]:
#         """
#         Classifies more than one rectangle in image.
#
#         Args:
#             img (np.ndarray): image
#             rects (list[Rectangle]): list of rectangles to classify
#
#         Returns:
#             list[Tuple[str, float]]: list of tuples of label and confidence
#         """
#         num_rects = len(rects)
#
#
#         return []
#
#     def classify_one(self, img, rect: Rectangle) -> Tuple[str, float]:
#         """
#         Classifies a single rectangle.
#
#         Args:
#             img (np.ndarray): image
#             rect (Rectangle): rectangle to classify
#
#         Returns:
#             Tuple[str, float]: tuple of label and confidence
#         """
#
#         return ("Test", 1)