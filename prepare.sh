#!/bin/sh

mkdir DKPProfiler
cp *.* DKPProfiler
zip -r -9 ~/DKPProfiler.zip DKPProfiler --exclude DKPProfiler/*~ DKPProfiler/*.zip
rm -fr DKPProfiler
