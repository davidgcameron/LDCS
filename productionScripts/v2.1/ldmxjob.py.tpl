#!/bin/python3

import os
import sys
import json

from LDMX.Framework import ldmxcfg

# set a 'pass name'; avoid sim or reco(n) as they are apparently overused
p=ldmxcfg.Process("v12")

#import all processors
from LDMX.SimCore import generators
from LDMX.SimCore import simulator
from LDMX.Biasing import filters

from LDMX.Ecal import digi
from LDMX.Ecal import vetos
from LDMX.EventProc import hcal
from LDMX.EventProc.simpleTrigger import simpleTrigger 
from LDMX.EventProc.trackerHitKiller import trackerHitKiller
from LDMX.EventProc.trigScintDigis import TrigScintDigiProducer

from LDMX.Detectors.makePath import *

from LDMX.SimCore import simcfg

#
# Instantiate the simulator.
#
sim = simulator.simulator("mySim")

#
# Set the path to the detector to use. 
#
sim.setDetector( 'ldmx-det-v12', True  )
sim.scoringPlanes = makeScoringPlanesPath('ldmx-det-v12')

#
# Set run parameters
#
sim.runNumber = RUNNUMBER
sim.description = "ECal photo-nuclear, xsec bias 450"
sim.randomSeeds = [ SEED1 , SEED2 ]
sim.beamSpotSmear = [20., 80., 0]

#
# Fire an electron upstream of the tagger tracker
#
sim.generators = [ generators.single_4gev_e_upstream_tagger() ]


#
# Enable and configure the biasing
#
sim.biasingOn(True)
sim.biasingConfigure('photonNuclear', 'ecal', 2500., 450)

#
# Configure the sequence in which user actions should be called.
#
sim.actions = [ filters.TaggerVetoFilter(),
                                    filters.TargetBremFilter(),
                                    filters.EcalProcessFilter(), 
                                    filters.TrackProcessFilter.photo_nuclear() ]

findableTrack = ldmxcfg.Producer("findable", "ldmx::FindableTrackProcessor")

trackerVeto = ldmxcfg.Producer("trackerVeto", "ldmx::TrackerVetoProcessor")


ecalDigi   =digi.EcalDigiProducer('EcalDigis')
ecalSim2Rec=digi.EcalRecProducer('ecalRecon')
ecalVeto   =vetos.EcalVetoProcessor('ecalVetoBDT')
hcalDigis  =hcal.HcalDigiProducer('hcalRecon')
hcalVeto   =hcal.HcalVetoProcessor('hcalVeto')

tsDigisUp  =TrigScintDigiProducer.up()
tsDigisTag  =TrigScintDigiProducer.tagger()
tsDigisDown  =TrigScintDigiProducer.down()

p.sequence=[ sim, ecalDigi, ecalSim2Rec, ecalVeto, hcalDigis, hcalVeto, tsDigisUp, tsDigisTag, tsDigisDown, trackerHitKiller, simpleTrigger, findableTrack, trackerVeto ]

p.outputFiles=["simoutput.root"]

p.maxEvents = 100000

#print this many events to stdout (independent on number of events, edge case: round-off effects when not divisible. so can go up by a factor 2 or so)
logEvents=20 
if p.maxEvents < logEvents :
     logEvents = p.maxEvents
p.logFrequency = int( p.maxEvents/logEvents )

with open('parameterDump.json', 'w') as outfile:
     json.dump(p.parameterDump(),  outfile, indent=4)


     
