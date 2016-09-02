from flask import Flask, abort
import htcondor
import socket

app = Flask(__name__)

@app.route("/health")
def health():
  coll = htcondor.Collector(socket.gethostname())
  try:
    ## retrieve workers
    results = coll.query(htcondor.AdTypes.Startd, "true", ["Name"])
    return 'OK', 200
  except:
    abort(401) 

if __name__ == '__main__':
    app.run(host= '0.0.0.0')
