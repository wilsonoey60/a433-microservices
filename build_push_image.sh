#!/bin/bash

# Task 1: Access Cloud Code
echo "Copy the IDE URL from the lab panel and paste it into a new browser window."

# Open terminal
echo "Opening a new terminal in the IDE..."
# (Assuming that opening terminal is a manual step)

# Check Python version
echo "Checking Python version..."
python --version

# Check TensorFlow version
echo "Checking TensorFlow version..."
python -c "import tensorflow;print(tensorflow.__version__)"

# Upgrade pip
echo "Upgrading pip..."
pip3 install --upgrade pip

# Install google-cloud-logging
echo "Installing google-cloud-logging..."
/usr/bin/python3 -m pip install -U google-cloud-logging --user

# Install pylint
echo "Installing pylint..."
/usr/bin/python3 -m pip install -U pylint --user

# Upgrade tensorflow
echo "Upgrading TensorFlow..."
pip install --upgrade tensorflow

# Task 2: Start Coding
echo "Creating model.py and writing code for the model..."

cat <<EOF > model.py
# Import and configure logging
import logging
import google.cloud.logging as cloud_logging
from google.cloud.logging.handlers import CloudLoggingHandler
from google.cloud.logging_v2.handlers import setup_logging

cloud_logger = logging.getLogger('cloudLogger')
cloud_logger.setLevel(logging.INFO)
cloud_logger.addHandler(CloudLoggingHandler(cloud_logging.Client()))
cloud_logger.addHandler(logging.StreamHandler())

# Import TensorFlow
import tensorflow as tf

# Import numpy
import numpy as np

# Import tensorflow_datasets
import tensorflow_datasets as tfds

# Define, load and configure data
(ds_train, ds_test), info = tfds.load('fashion_mnist', split=['train', 'test'], with_info=True, as_supervised=True)

# Values before normalization
image_batch, labels_batch = next(iter(ds_train))
print("Before normalization ->", np.min(image_batch[0]), np.max(image_batch[0]))

# Define batch size
BATCH_SIZE = 32

# Normalize and batch process the dataset
ds_train = ds_train.map(lambda x, y: (tf.cast(x, tf.float32)/255.0, y)).batch(BATCH_SIZE)
ds_test = ds_test.map(lambda x, y: (tf.cast(x, tf.float32)/255.0, y)).batch(BATCH_SIZE)

# Examine the min and max values of the batch after normalization
image_batch, labels_batch = next(iter(ds_train))
print("After normalization ->", np.min(image_batch[0]), np.max(image_batch[0]))

# Define the model
model = tf.keras.models.Sequential([
    tf.keras.layers.Flatten(),
    tf.keras.layers.Dense(64, activation=tf.nn.relu),
    tf.keras.layers.Dense(10, activation=tf.nn.softmax)
])

# Compile the model
model.compile(optimizer=tf.keras.optimizers.Adam(),
              loss=tf.keras.losses.SparseCategoricalCrossentropy(),
              metrics=[tf.keras.metrics.SparseCategoricalAccuracy()])

# Train the model
model.fit(ds_train, epochs=5)

# Evaluate model performance
cloud_logger.info(model.evaluate(ds_test))

# Save the entire model as a SavedModel
model.save('saved_model')

# Reload a fresh Keras model from the saved model
new_model = tf.keras.models.load_model('saved_model')

# Summary of loaded SavedModel
new_model.summary()

# Save the entire model to a HDF5 file
model.save('my_model.h5')

# Recreate the exact same model, including its weights and the optimizer
new_model_h5 = tf.keras.models.load_model('my_model.h5')

# Summary of loaded h5 model
new_model_h5.summary()
EOF

# Run the script
echo "Running the model script..."
python model.py

echo "All tasks completed!"
