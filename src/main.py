import json
import time
import hashlib
import os
import hmac
import base64
import uuid
import requests
from fastapi import FastAPI, Response
from jinja2 import Template


app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": "World"}


def make_request(uri: str, **kwargs):
    apiHeader = {}
    token = os.environ.get("SWITCHBOT_TOKEN")
    secret = os.environ.get("SWITCHBOT_SECRET")
    if not token or not secret:
        raise ValueError("SWITCHBOT_TOKEN and SWITCHBOT_SECRET must be set")
    nonce = uuid.uuid4()
    t = int(round(time.time() * 1000))
    string_to_sign = "{}{}{}".format(token, t, nonce)

    string_to_sign = bytes(string_to_sign, "utf-8")
    secret = bytes(secret, "utf-8")

    sign = base64.b64encode(
        hmac.new(secret, msg=string_to_sign, digestmod=hashlib.sha256).digest()
    )

    # Build api header JSON
    apiHeader["Authorization"] = token
    apiHeader["Content-Type"] = "application/json"
    apiHeader["charset"] = "utf8"
    apiHeader["t"] = str(t)
    apiHeader["sign"] = str(sign, "utf-8")
    apiHeader["nonce"] = str(nonce)

    res = requests.get(
        f"https://api.switch-bot.com{uri}".format(**kwargs),
        headers=apiHeader,
    )

    res_json = json.loads(res.text)
    return res, res_json


_, res_json = make_request("/v1.1/devices")
device_id_name_map = {}
for d in res_json["body"]["deviceList"]:
    device_id_name_map[d["deviceId"]] = d["deviceName"]



@app.get("/metrics")
def read_item(target: str = ""):
    duration = time.time()

    global device_id_name_map
    res, res_json = make_request("/v1.1/devices/{target}/status", target=target)

    duration = time.time() - duration

    with open(os.path.dirname(__file__) + "/template.jinja", "r") as f:
        template = f.read()
    content = Template(template).render(
        {
            "duration": duration,
            "request_status": res.status_code,
            "api_status_code": res_json["statusCode"],
            "message": res_json["message"],
            "version": res_json["body"]["version"],
            "power": 1 if res_json["body"]["power"] == "on" else 0,
            "voltage": res_json["body"]["voltage"],
            "weight": res_json["body"]["weight"],
            "electricity_of_day": res_json["body"]["electricityOfDay"],
            "electric_current": res_json["body"]["electricCurrent"],
            "device_id": res_json["body"]["deviceId"],
            "device_type": res_json["body"]["deviceType"],
            "hub_device_id": res_json["body"]["hubDeviceId"],
            "name": device_id_name_map[target],
        }
    )

    return Response(
        content=content, media_type="text/plain; version=0.0.4", status_code=200
    )
