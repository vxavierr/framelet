import subprocess,time,os,json
from pathlib import Path
from PIL import Image
p=Path(__file__).resolve().parents[1]
folder=p/"build/tmp/scroll-framelet-results"
folder.mkdir(parents=True,exist_ok=True)
config=p/"build/tmp/scroll-framelet-config"
(config/"Framelet").mkdir(parents=True,exist_ok=True)
(config/"Framelet/Framelet.conf").write_text("[General]\nstyle=8\noutputDirectory="+str(folder)+"\n[migration]\ncaptura=true\n")
os.environ.update(XDG_CONFIG_HOME=str(config),XDG_DATA_HOME=str(p/"build/tmp/scroll-framelet-data"),TMPDIR=str(p/"build/tmp"))
before=set(folder.glob("Framelet-*.png"))
fixture=subprocess.Popen(["qml6",str(p/"tests/LocalScrollFixture.qml")],stdout=(p/"fixture-qa.log").open("w"),stderr=subprocess.STDOUT)
capture=None
def key(k,mods=""):
    for state in ["down","up"]:
        subprocess.run(["hyprctl","dispatch",f'hl.dsp.send_key_state({{mods="{mods}",key="{k}",state="{state}"}})'],check=True);time.sleep(.05)
try:
    time.sleep(2)
    clients=json.loads(subprocess.check_output(["hyprctl","clients","-j"]))
    target=next(c for c in clients if c["pid"]==fixture.pid)
    px=target["at"][0]+target["size"][0]//2;py=target["at"][1]+target["size"][1]//2
    capture=subprocess.Popen([str(Path.home()/".config/omarchy/plugins/vxavierr.framelet/bin/framelet"),"--scroll"],env=dict(os.environ,OMAFRAME_SCROLL_DEBUG="1"),stdout=(p/"scroll-qa-final.log").open("w"),stderr=subprocess.STDOUT)
    time.sleep(2)
    subprocess.run([str(p/"build-native/local-pointer"),str(px),str(py)],check=True)
    automatic=False
    for i in range(35):
        time.sleep(1)
        if subprocess.check_output(["hyprctl","submap"]).decode().strip()=="framelet":
            automatic=True;break
    if not automatic:
        key("RETURN");time.sleep(2)
    key("S","CTRL")
    capture.wait(timeout=12)
    created=set(folder.glob("Framelet-*.png"))-before
    assert len(created)==1,created
    output=created.pop();im=Image.open(output)
    runs=[];start=None
    for y in range(im.height+1):
        rgb=im.getpixel((100,y))[:3] if y<im.height else (0,0,0)
        colored=max(rgb)-min(rgb)>60
        if colored and start is None:start=y
        if not colored and start is not None:runs.append((start,y-start));start=None
    result={"automatic":automatic,"file":str(output),"size":im.size,"bars":runs}
    (p/"scroll-proof.json").write_text(json.dumps(result,indent=2))
    print(json.dumps(result))
    assert automatic and len(runs)==60 and all(h==24 for y,h in runs),result
    assert all(runs[i+1][0]-runs[i][0]==72 for i in range(59)),result
finally:
    if capture and capture.poll() is None:capture.terminate()
    fixture.terminate();fixture.wait(timeout=5)
