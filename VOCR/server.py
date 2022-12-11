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
	s.close()
	sys.exit(0)

def guess(img):
	img = decode_jpeg(img)
	img = resize(img, (224, 224))
	img = expand_dims(img, axis=0)
	pred = model(img).numpy()
	return decode_predictions(pred, top=1)[0][0][1]

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
while True:
	c, addr = s.accept()
	data = c.recv(4)
	buf = int.from_bytes(data, "little")
	img = c.recv(buf)
	while len(img)<buf:
		img += c.recv(buf-len(img))
	data = guess(img)
	c.send(data.encode("utf-8"))
	c.close()
