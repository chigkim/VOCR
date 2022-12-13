import socket
from tensorflow.keras.applications import MobileNetV3Small
from tensorflow.keras.applications.mobilenet import decode_predictions
from tensorflow.image import resize
from tensorflow.io import decode_jpeg, read_file
from tensorflow  import expand_dims
from utils import get_rects_for_image
import signal
import time
import sys
import struct
import json

def signal_handler(sig, frame):
	print("Signal:", sig)
	c.close()
	s.close()
	sys.exit(0)

def recv():
	data = c.recv(4)
	buf = int.from_bytes(data, "little")
	print("Python: Receiving", buf)
	data = c.recv(buf)
	left = buf-len(data)
	while left>0:
		data += c.recv(left)
		left = buf-len(data)
	return data

def send(data):
	data = data.encode("UTF-8")
	length = len(data)
	print("Python: Sending", length)
	length = length.to_bytes(4, byteorder="little")
	data = length+data
	c.send(data)

s = socket.socket()
signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGABRT, signal_handler)
signal.signal(signal.SIGINT, signal_handler)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
port = 12345
s.bind(('localhost', port))
s.listen(1)
while True:
	print("Waiting for a new connection...")
	c, addr = s.accept()
	img_bytes = recv()
	img_np = decode_jpeg(img_bytes).numpy()
	send("Got Image")
	data = recv()
	data = json.loads(data.decode("utf-8"))
	texts = data["texts"]
	boxes = data['boxes']
	print(texts)
	print(boxes)
	data = get_rects_for_image(img_np, img_np.shape[1], img_np.shape[0], boxes, texts)
	send(json.dumps(data))
	c.close()
