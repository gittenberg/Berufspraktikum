#!/usr/bin/env python
# -*- coding: utf-8 -*-

from os import listdir
from os.path import join
from subprocess import call, Popen, PIPE, STDOUT
import Image

from global_vars import SIC_PROCESSED, SIC_ROOT


def generate_density_plots(outpath=join(SIC_ROOT, SIC_PROCESSED)):
    # Executes the following command:
    # >Rscript plot_spot.R --args cellID_file boundary_file interior_file out_name
    
    print "----------------------------------------------------"
    print "Generating density plots..."
    defaultviewer = "eog" # Eye of Gnome, for Linux/Gnome environment
    rscriptname = "plot_spot.R"

    lout = listdir(outpath)
    for filename in sorted(lout):
        if filename.endswith("_all"):
            print "Considering file:", filename
            cellID_file = filename
            boundary_file = filename[:-4]+".tif_BOUND.txt"
            interior_file = filename[:-4]+".tif_INT.txt"
            out_name = filename[:-4]+"_density"
            execstring = ['Rscript', rscriptname, '--args', join(outpath, cellID_file), join(outpath, boundary_file), join(outpath, interior_file), join(outpath, out_name)]
            print "External call:", " ".join(execstring)
            call(execstring)
            Image.open(join(outpath, out_name)).show()
            # Open picture in default viewer
            #Popen([defaultviewer, join(outpath, out_name)], stdout=PIPE, stderr=STDOUT)

    print "Finished generating density plots."


def draw_spot_in_image(filename, x=200, y=150, outpath=join(SIC_ROOT, SIC_PROCESSED), markerwidth = 2*1):
    print "----------------------------------------------------"
    print "Drawing spot..."
    #defaultviewer = "eog" # Eye of Gnome, for Linux/Gnome environment

    execstring = "convert %s -fill red -strokewidth 10 -draw line_0,0_0,0 %s" % (join(outpath, filename), join(outpath, filename))
    execsubstring = execstring.split()
    for j in range(len(execsubstring)):
        if execsubstring[j] == "line_0,0_0,0":
            execsubstring[j] = 'line %s,%s %s,%s' % (x+markerwidth/2, y, x-markerwidth/2, y)
    print "External call:", " ".join(execsubstring)
    call(execsubstring)
    
    execstring = "convert %s -fill red -strokewidth 10 -draw line_1,1_1,1 %s" % (join(outpath, filename), join(outpath, filename))
    execsubstring = execstring.split()
    for j in range(len(execsubstring)):
        if execsubstring[j] == "line_1,1_1,1":
            execsubstring[j] = 'line %s,%s %s,%s' % (x, y+markerwidth/2, x, y-markerwidth/2)
    print "External call:", " ".join(execsubstring)
    call(execsubstring)

    
def draw_spots_for_session(outpath=join(SIC_ROOT, SIC_PROCESSED), infofile="all_spots.xls"):
    with open(join(outpath, infofile), "r") as readfile:
        next(readfile)
        for line in readfile: #print line
            words = line.split()
            draw_spot_in_image(words[0] + ".tif.out.tif", float(words[2]), float(words[3]))
    
    readfile.close()
    lout = listdir(outpath)
    for filename in sorted(lout):
        if "out" in filename and "GFP" in filename:
            Image.open(join(outpath, filename)).show()
    # Open picture in default viewer
    #Popen([defaultviewer, join(outpath, filename)], stdout=PIPE, stderr=STDOUT)


if __name__ == '__main__':
    #generate_density_plots()
    draw_spots_for_session()

