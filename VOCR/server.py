import socket
from tensorflow.keras.models import load_model
from tensorflow.io import decode_jpeg
from utils import get_rects_for_image
import signal
import time
import sys
import struct
import json
import os

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
print(os.getcwd())
model_loc = "/VOCR/model.h5"
model = load_model(os.getcwd() + model_loc)
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
	data = get_rects_for_image(img_np, boxes, texts, model)
	send(json.dumps(data))
	c.close()
