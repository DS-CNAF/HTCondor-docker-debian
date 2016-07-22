from flask import Flask, abort
import htcondor
import socket

app = Flask(__name__)

@app.route("/health")
def health():
  coll = htcondor.Collector(socket.gethostname())
  try:
    results = coll.query(htcondor.AdTypes.Startd, "true", ["Name"])
    return "OK" 
  except:
    abort(401) 

if __name__ == '__main__':
    app.run(host= '0.0.0.0')
