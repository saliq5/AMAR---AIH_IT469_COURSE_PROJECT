from flask import Flask, request, jsonify
from io import BytesIO
import torch
import torchvision
from PIL import Image
import torchvision.transforms as T
import numpy as np
import cv2
import base64
import os

app = Flask(__name__)

# Load model only once when server starts
model = torchvision.models.detection.maskrcnn_resnet50_fpn(pretrained=True)
model.eval()
transform = T.Compose([T.ToTensor()])

def segment_medicines(image_bytes, threshold=0.5, iou_threshold=0.5):
    try:
        # Convert bytes to PIL Image directly
        image = Image.open(BytesIO(image_bytes)).convert("RGB")
        img_tensor = transform(image).unsqueeze(0)
        
        # Convert PIL image to CV2 format for processing
        cv2_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)

        with torch.no_grad():
            predictions = model(img_tensor)

        masks = predictions[0]['masks'].numpy()
        boxes = predictions[0]['boxes'].numpy()
        scores = predictions[0]['scores'].numpy()

        valid_predictions = [i for i in range(len(scores)) if scores[i] > threshold]
        
        segmented_images = []
        saved_boxes = []

        for i in valid_predictions:
            box = boxes[i].astype(int)
            iou = calculate_iou(box, saved_boxes)

            if all(i < iou_threshold for i in iou):
                mask = masks[i][0] > 0.5
                cropped_image = cv2_image[box[1]:box[3], box[0]:box[2]]
                mask_cropped = mask[box[1]:box[3], box[0]:box[2]]
                segmented_image = np.zeros_like(cropped_image)
                segmented_image[mask_cropped] = cropped_image[mask_cropped]

                segmented_images.append(segmented_image)
                saved_boxes.append(box)

        return segmented_images, None
    except Exception as e:
        return None, str(e)

def calculate_iou(box, saved_boxes):
    box_area = (box[2] - box[0]) * (box[3] - box[1])
    ious = []

    for saved_box in saved_boxes:
        x1 = max(box[0], saved_box[0])
        y1 = max(box[1], saved_box[1])
        x2 = min(box[2], saved_box[2])
        y2 = min(box[3], saved_box[3])

        inter_area = max(0, x2 - x1) * max(0, y2 - y1)
        union_area = box_area + (saved_box[2] - saved_box[0]) * (saved_box[3] - saved_box[1]) - inter_area
        
        iou = inter_area / union_area if union_area > 0 else 0
        ious.append(iou)

    return ious

@app.route('/segment', methods=['POST'])
def segment():
    try:
        if 'image' not in request.files:
            return jsonify({
                "error": "No image provided",
                "detail": "Request must include an image file"
            }), 400

        # Read image data directly from the request
        image_file = request.files['image']
        image_bytes = image_file.read()

        # Validate image data
        if not image_bytes:
            return jsonify({
                "error": "Empty image data",
                "detail": "The provided image file is empty"
            }), 400

        # Process the image
        segmented_images, error = segment_medicines(image_bytes)
        
        if error:
            return jsonify({
                "error": "Processing failed",
                "detail": error
            }), 500

        if not segmented_images:
            return jsonify({
                "error": "No medicines detected",
                "detail": "The model did not detect any medicines in the image"
            }), 404

        # Convert segmented images to base64 with proper encoding
        result_images = []
        for img in segmented_images:
            # Ensure high quality JPEG encoding
            encode_params = [cv2.IMWRITE_JPEG_QUALITY, 100]
            _, img_encoded = cv2.imencode('.jpg', img, encode_params)
            img_base64 = base64.b64encode(img_encoded).decode('utf-8')
            result_images.append(img_base64)

        return jsonify({
            "segmented_images": result_images,
            "count": len(result_images)
        })

    except Exception as e:
        return jsonify({
            "error": "Server error",
            "detail": str(e)
        }), 500

if __name__ == "__main__":
    print("Server starting on http://0.0.0.0:5100")
    app.run(host="0.0.0.0", port=5100, debug=False)