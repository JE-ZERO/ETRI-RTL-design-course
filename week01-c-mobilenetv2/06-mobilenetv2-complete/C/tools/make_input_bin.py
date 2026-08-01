from PIL import Image
import numpy as np
import sys


def make_input_bin(image_path, output_path):
    img = Image.open(image_path).convert("RGB")
    img = img.resize((224, 224), Image.BILINEAR)

    arr = np.array(img).astype(np.float32) / 255.0
    arr = arr.transpose(2, 0, 1)
    arr = np.ascontiguousarray(arr, dtype=np.float32)

    arr.tofile(output_path)

    print("saved:", output_path)
    print("shape:", arr.shape)
    print("dtype:", arr.dtype)
    print("bytes:", arr.nbytes)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("usage: python make_input_bin.py input_image output_bin")
        sys.exit(1)

    make_input_bin(sys.argv[1], sys.argv[2])