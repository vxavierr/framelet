import subprocess,time,json,os
from pathlib import Path
from PIL import Image
p=Path(__file__).resolve().parents[1]
folder=Path.home()/"Pictures/Capturas"
before=set(folder.glob("Framelet-*.png"))
os.environ['TMPDIR']=str(p/'build/tmp')
fixture=subprocess.Popen(["qml6",str(p/"tests/LocalRegionFixture.qml")],stdout=(p/"region-qa.log").open("w"),stderr=subprocess.STDOUT)
try:
    time.sleep(2)
    subprocess.run(["omarchy-shell","shell","summon","vxavierr.framelet", '{"capture":"smart"}'],check=True);time.sleep(3)
    def layers():
        d=json.loads(subprocess.check_output(["hyprctl","layers","-j"]))
        return [x["namespace"] for v in d.values() for a in v["levels"].values() for x in a]
    assert "framelet-selection" in layers(),layers()
    subprocess.run([str(p/"build-native/local-pointer"),"400","200","1000","600"],check=True);time.sleep(2)
    assert "framelet-finishes" in layers(),layers()
    subprocess.run([str(p/"build-native/local-pointer"),"460","260","850","490"],check=True);time.sleep(1)
    subprocess.run(["hyprctl","dispatch", 'hl.dsp.send_key_state({mods="CTRL",key="S",state="down"})'],check=True);time.sleep(0.05);subprocess.run(["hyprctl","dispatch", 'hl.dsp.send_key_state({mods="CTRL",key="S",state="up"})'],check=True)
    for i in range(10):
        time.sleep(0.5)
        if "framelet-finishes" not in layers():break
    created=set(folder.glob("Framelet-*.png"))-before
    assert len(created)==1,created
    output=created.pop();im=Image.open(output).convert("RGB")
    red=sum(r>180 and g<150 and b<120 for r,g,b in im.getdata())
    result={"file":str(output),"size":im.size,"arrow_pixels":red,"submap":subprocess.check_output(["hyprctl","submap"]).decode().strip()}
    (p/"region-proof.json").write_text(json.dumps(result,indent=2));print(json.dumps(result))
    assert im.size==(600,400) and red>300 and result["submap"]=="default",result
finally:
    fixture.terminate();fixture.wait(timeout=5)
