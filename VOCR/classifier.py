from tensorflow.image import resize
import numpy as np
# label_map = {0: 'arrow', 1: 'button', 2: 'dropdown', 3: 'icon', 4: 'knob', 5: 'light', 6: 'meter',
#  7: 'multiple elements', 8: 'multiple knobs', 9: 'needle', 10: 'non-interactive',
#  11: 'radio button', 12: 'slider', 13: 'switch', 14: 'unknown'}

def classify(im, boxes, model, img_size=(224,224), output_type='int'):
	'''
	:param im: image to slice boxes from
	:param boxes: the box value needs to be a list of tuples (even if it is a list of
	a single tuple) where each tuple is (top x, top y, width, height)
	:param model: Tensorflow model to use to classify
	:param img_size: tuple, by default it is 224 by 224, but it could be modified if the model is
	also modified
	:param output_type: string, by default "int", culd be "str" to output label name
	:return:
	'''
	imgs = []
	for topx, topy, b_width, b_height in boxes:
		box = im[topy:topy + b_height, topx:topx + b_width, :]
		resized = resize(box, img_size)
		imgs.append(resized)
	imgs = np.array(imgs)
	preds = model.predict(imgs)
	classes = preds.argmax(axis=1)
	confs = preds.max(axis=1)
	classification = tuple(zip(classes, confs))
	print("Classification ", classification)
	return classification