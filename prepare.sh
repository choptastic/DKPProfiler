#!/bin/sh

# This will simply generate a DKPProfiler.zip file in your home directory.

mkdir DKPProfiler
cp *.* DKPProfiler
zip -r -9 ~/DKPProfiler.zip DKPProfiler --exclude DKPProfiler/*~ DKPProfiler/*.zip
rm -fr DKPProfiler
