from ij import IJ
from ij.process import ImageStatistics as IS
from ij.gui import Roi, Line  
from ij.process import FloatProcessor

imp = IJ.getImage()
ip = imp.getProcessor().convertToFloat() # type 'ij.ImagePlus'
pixels = ip.getPixels()			 		 # type 'array'
options = IS.MEAN | IS.MEDIAN | IS.MIN_MAX
stats = IS.getStatistics(ip, options, imp.getCalibration())

def all_indices(value, qlist):
	# returns list of indices of elements in qlist that have value
    indices = []
    idx = -1
    while True:
        try:
            idx = qlist.index(value, idx+1)
            indices.append(idx)
        except ValueError:
            break
    return indices

# Print image details
print "title:", imp.title
width  = imp.width
height = imp.height
print "number of slices:", imp.getNSlices()
print "number of channels:", imp.getNChannels()
print "number of time frames:", imp.getNFrames()

brightestpixellist = all_indices(stats.max, list(pixels))
print "pixels with max. value:", brightestpixellist

for bp in brightestpixellist:
    x = bp%imp.width
    y = bp/imp.width
    print x, y

fp = FloatProcessor(width, height, pixels, None)
roi = Line(0, 0, 100, 100)
fp.setRoi(roi)
fp.setValue(8000.0)
fp.draw(roi)
ImagePlus("bla", fp).show()
