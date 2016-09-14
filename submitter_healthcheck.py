from flask import Flask, abort
import htcondor
import socket

app = Flask(__name__)

@app.route("/health")
def health():
  try:
    for schedd_ad in htcondor.Collector().locateAll(htcondor.DaemonTypes.Schedd):
      if schedd_ad['Machine'] == socket.gethostname():
        return 'OK', 200
    abort(401) 
  except:
    abort(401) 

if __name__ == '__main__':
    app.run(host= '0.0.0.0')
