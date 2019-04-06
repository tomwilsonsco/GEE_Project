#Tom Wilson January 2019

import numpy as np
import matplotlib.pyplot as plt

import rasterio
import sklearn.cluster

inputImg = r'C:\temp\Sentinel_tests\clipS1.tif'

with rasterio.open(inputImg) as allBands:
    data = np.array([allBands.read(1), allBands.read(2), allBands.read(4)])

data.shape

plt.figure(figsize=(12, 12))
plt.imshow(np.dstack(data))

samples = data.reshape((3, -1)).T
samples.shape

clf = sklearn.cluster.KMeans(n_clusters=2)

labels = clf.fit_predict(samples)
labels.shape


plt.figure(figsize=(12, 12))
plt.imshow(labels.reshape((2514, 2299)), cmap="Set1")

