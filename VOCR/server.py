import socket
from tensorflow.keras.applications import MobileNetV3Small
from tensorflow.keras.applications.mobilenet import decode_predictions
from tensorflow.image import resize
from tensorflow.io import decode_jpeg
from tensorflow  import expand_dims
import signal
import time
import sys

def signal_handler(sig, frame):
	print("Signal:", sig)
	c.close()
	s.close()
	sys.exit(0)

def guess(img):
	img = decode_jpeg(img)
	img = resize(img, (224, 224))
	img = expand_dims(img, axis=0)
	pred = model(img).numpy()
	return decode_predictions(pred, top=1)[0][0][1]

def recv():
	data = c.recv(4)
	buf = int.from_bytes(data, "little")
	print("Receiving", buf)
	data = c.recv(buf)
	left = buf-len(data)
	while left>0:
		data += c.recv(left)
		left = buf-len(data)
	return data

def send(data):
	data = data.encode("UTF-8")
	length = len(data)
	print("Sending", length)
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
print("Listening...")
model = MobileNetV3Small()
c, addr = s.accept()
while True:
	data = recv()
	data = guess(data)
	send(data)
