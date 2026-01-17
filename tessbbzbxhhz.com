<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Finger Drawing - Mobile</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/hands/hands.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/camera_utils/camera_utils.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/drawing_utils/drawing_utils.js"></script>

  <style>
    body {
      margin: 0;
      overflow: hidden;
      background: black;
      font-family: Arial;
    }
    video, canvas {
      position: absolute;
      width: 100vw;
      height: 100vh;
      object-fit: cover;
    }
    #tools {
      position: fixed;
      bottom: 10px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(0,0,0,0.6);
      padding: 10px;
      border-radius: 10px;
      color: white;
    }
    button {
      padding: 8px 12px;
      margin: 5px;
      border: none;
      border-radius: 6px;
      font-size: 14px;
    }
  </style>
</head>

<body>

<video id="video" autoplay></video>
<canvas id="canvas"></canvas>

<div id="tools">
  ✋ سبابة = رسم  
  ✊ قبضة = مسح  
  <button onclick="clearCanvas()">مسح الكل</button>
</div>

<script>
const video = document.getElementById("video");
const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");

canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

let lastX = null;
let lastY = null;

function clearCanvas() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
}

const hands = new Hands({
  locateFile: file => 
    `https://cdn.jsdelivr.net/npm/@mediapipe/hands/${file}`
});

hands.setOptions({
  maxNumHands: 1,
  modelComplexity: 1,
  minDetectionConfidence: 0.7,
  minTrackingConfidence: 0.7
});

hands.onResults(results => {
  if (!results.multiHandLandmarks) return;

  const landmarks = results.multiHandLandmarks[0];

  const indexTip = landmarks[8]; // رأس السبابة
  const indexBase = landmarks[6]; // قاعدة السبابة

  const x = indexTip.x * canvas.width;
  const y = indexTip.y * canvas.height;

  const fingerUp = indexTip.y < indexBase.y;

  if (fingerUp) {
    ctx.strokeStyle = "yellow";
    ctx.lineWidth = 5;
    ctx.lineCap = "round";

    if (lastX !== null) {
      ctx.beginPath();
      ctx.moveTo(lastX, lastY);
      ctx.lineTo(x, y);
      ctx.stroke();
    }
    lastX = x;
    lastY = y;
  } else {
    lastX = null;
    lastY = null;
  }
});

const camera = new Camera(video, {
  onFrame: async () => {
    await hands.send({ image: video });
  },
  width: 1280,
  height: 720
});

camera.start();
</script>

</body>
</html>
