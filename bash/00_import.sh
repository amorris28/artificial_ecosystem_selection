#!/bin/bash
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path 00_raw_seqs \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path 01_qiime_seqs/demux-paired-end.qza
qiime demux summarize \
  --i-data 01_qiime_seqs/demux-paired-end.qza \
  --o-visualization 01_qiime_seqs/demux-paired-end.qzv
