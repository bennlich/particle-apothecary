extensions [matrix]
globals [totalMeasurements measurementsList measurementsTicksList temp maxInteger version
         expSlope expRSquared  powerSlope powerRSquared]

patches-own [particleDensity antiParticleDensity]

;fermions
breed [quarks quark]

breed [antiquarks antiquark]

breed [electrons electron]
breed [positrons positron]
breed [neutrinos neutrion]
breed [antineutrinos antineutrino]

breed [testers test]

;bosons
breed [photons photon]
photons-own [energy]

turtles-own [birthTick lifeTime infinite? old? annihilated?]

to startup
  setup
end

to setup
  ca
  set maxInteger 99999999
  set measurementsList []
  set measurementsTicksList []
  set version "0026"
 ; import-drawing "legend.png"
  set-shapes
  if autoRandom? [set randomSeed random 9999]
  random-seed randomSeed
  reset-timer
  reset-ticks
end

to go
  tick
  handleSliderConstraints
  if count turtles > 30000 [stop]
  ; handle j
  if h != i [set i h]
  if numPhotonsCreated != numPhotonsRequired [set numPhotonsRequired numPhotonsCreated]
  kill-particles
  step-vacuum
  make-measurements
 ; ask turtles [set label round lifetime]
  if count turtles > 100000 [stop ask n-of 10 turtles [die]]
  if layout-space? [layout-space]
 ; if visualizeFieldDensity? [visualize-field-density]
  if visualizeSpaceTime? [visualize-space-time]
  if totalMeasurements > 0 [
    set measurementsList lput totalMeasurements  measurementsList
    set measurementsTicksList lput ticks measurementsTicksList]
  if ticks > 0 and ticks mod 5 = 0 [fitTrendlines]
end

to kill-particles
  ask turtles with [birthTick + lifeTime <= ticks] [die]
end

to handleSliderConstraints
  if lockItoH? [set i h]
end


to make-measurements

  ;handle R
    ask (turtle-set quarks antiquarks) [
      if R > random-float 1 [
        ifelse breed = quarks
            [ set breed antiquarks ask my-links [die] set color one-of [cyan magenta yellow] measurements-inc register-birth]
            [set breed quarks ask my-links [die] set color one-of [red blue green] measurements-inc register-birth ]    ]]
   ; handle RM
    if any? (turtle-set quarks antiquarks) [
      ask (turtle-set quarks antiquarks) [
        ask other (turtle-set quarks antiquarks) with [ who > [who] of myself] [
          if  [annihilated? != true] of myself [
         ;  face myself fd distance myself / 32
         ; if .1 > random-float 1 [create-link-with myself []
           ifelse ([breed] of myself != breed )
             [ if RM > random-float 1 [
                   measurements-inc
                   hatch-photons numPhotonsCreated [register-birth set color white]
               ifelse old? = true and [old? = true] of myself
                   ; we're both old so annihilate
                   [ask myself [set annihilated? true] die ]
                   ; one of us is new
                   [ask myself [if not old? or (old? and newParticleInfluence > random-float 1) [ set annihilated? true]]
                    if not old? or (old? and newParticleInfluence > random-float 1) [die] ]
               ]
            ]
            ; breeds are equal
            [ask myself [lifetime-inc] lifetime-inc measurements-inc]
           ]
         ]
        if annihilated? = true [die]  ; improve efficiency by halting in loop
      ]
    ]

; handle A                                                      electron + antineutrino ***> antiquark (changes color c->m->y->c)

     if any? antiquarks and any? (turtle-set electrons antineutrinos) [
      ask (turtle-set electrons antineutrinos) [
        ask other (turtle-set electrons antineutrinos) with [ who > [who] of myself] [
          if  [annihilated? != true] of myself and A > random-float 1 [
           if ([breed] of myself != breed )
             [measurements-inc ask myself [set annihilated? true]  ask one-of antiquarks [shift-color] die ]
           ]
          ]
       if annihilated? = true [die]  ; could improve efficiency by halting in loop and only selecting other breed
      ]
    ]

;                                                                positrons + neutrinos ***> quark (changes color r->g->b->r)
   if any? quarks and any? (turtle-set positrons neutrinos) [
    ask (turtle-set positrons neutrinos) [
        ask other (turtle-set positrons neutrinos) with [ who > [who] of myself] [
          if  [annihilated? != true] of myself and A > random-float 1 [
           if ([breed] of myself != breed )
             [measurements-inc ask myself [set annihilated? true] ask one-of quarks [shift-color] die  ]
           ]
          ]
       if annihilated? = true [die]  ; improve efficiency by halting in loop and only selecting other breed
      ]
  ]


; handle B
;                                                                 quark    changes color  ***> positron + neutrino
;                                                                 antiquark changes color ***> electron + antineutrino

  ask quarks with [old?] [if B > random-float 1  [
      hatch-positrons 1 [register-birth set color violet] hatch-neutrinos 1 [register-birth set color orange] ask one-of quarks [shift-color] measurements-inc] ]
  ask antiquarks with [old?] [ if B > random-float 1 [
      hatch-electrons 1 [register-birth set color violet] hatch-antineutrinos 1 [register-birth set color orange] ask one-of antiquarks [shift-color] measurements-inc] ]

; handle C                                                        photons -> quark + antiquark
    repeat count photons / numPhotonsRequired [
        if C >= random-float 1 [
           let aParticle nobody
           create-quarks 1  [register-birth set color one-of [red green blue] set aParticle self]
           create-antiquarks 1 [register-birth set color one-of [cyan magenta yellow] create-link-with aParticle [set color [255 255 255 64]] move-to aParticle forward 3]
            ask n-of numPhotonsRequired photons [die]]
    ]

; ; handle D
;   ask quarks [if D > random-float 1 [
;    if any? antiquarks [ ask one-of antiquarks [die] hatch-photons 1 [register-birth set color white] die]]]

; handle K                                                        positron electron ->  photons
    if K > random-float 1 [
      if any? positrons and any? electrons [
        create-photons numPhotonsCreated [register-birth set color white]
        ask one-of positrons [die] ask one-of electrons [die]
      ]
    ]

; handle L                                                        photons -> positron electron
    if L > random-float 1 [
      if count photons > numPhotonsRequired [
        create-positrons 1 [register-birth set color violet]
        create-electrons 1 [register-birth set color violet]
        ask n-of numPhotonsRequired photons [die]
      ]
    ]

; handle M                                                        old quark =-> electron + antineutrino
  ask quarks with [old? = true] [ if M >= random-float 1  [measurements-inc shift-color hatch-electrons 1 [register-birth set color violet] hatch-antineutrinos 1 [register-birth set color orange]]]

; handle N                                                        old antiquark =-> positron + neutrino
  ask antiquarks with [old? = true][if N >= random-float 1 [measurements-inc shift-color hatch-positrons 1 [register-birth set color violet] hatch-neutrinos 1 [register-birth set color orange]]]

; handle O                                                        neutrino < == > antineutrino
  ask (turtle-set neutrinos antineutrinos) [if O > random-float 1 [set breed ifelse-value (breed = neutrinos) [antineutrinos] [neutrinos] register-birth ]]

; handle P                                                        electron < == > positron
  ask (turtle-set electrons positrons) [if O > random-float 1 [set breed ifelse-value (breed = electrons) [positrons] [electrons] register-birth ]]

end

to step-vacuum
  let numParticles 1
  if useProportional? [set numParticles max (list 1 (totalFermionsAndLeptons * proportionalCreation))]

 ; handle g and G
 repeat random-poisson  meanCreationRate / HboxT [
  if G >= random-float 1  [
    let particle1 nobody let particle2 nobody
    create-quarks numParticles [set particle1 self register-birth set color one-of [red green blue] set particle1 self]
    create-antiquarks numParticles [set particle2 self register-birth set color one-of [cyan magenta yellow] create-link-with particle1 [set color [255 255 255 64]] move-to particle1 forward 3]
    ; enforce single particle creation
    if singlePair > random-float 1 [ask one-of (turtle-set particle1 particle2) [die]]
   ]
  if H >= random-float 1 [
    create-neutrinos numParticles [register-birth set color orange]
    create-positrons numParticles [register-birth set color violet] ]

  if I >= random-float 1 [
    create-electrons numParticles [register-birth  set color violet]
    create-antineutrinos numParticles [register-birth set color orange] ]
  ]
end

to register-birth
  set old? false
  set lifetime HBoxT * LifetimeExtension
  if breed = photons [set lifetime maxInteger set energy count turtles]
  set birthTick ticks
  setxy random-xcor random-ycor
end


to layout-space
  if not visualizeFieldDensity? [ask patches [set pcolor black]]
  ask turtles [st] ask links [set hidden? false]
  repeat repeatLayout [layout-spring turtles links k resting-length repulsion]
end

;to visualize-field-density
;  ask turtles [ht] ask links [set hidden? true]
;  ask patches [set particleDensity count particles-here  set antiparticleDensity count antiparticles-here]
;  repeat fieldDiffuseAmount [diffuse particleDensity 0.5   diffuse antiparticleDensity 0.5]
;  let maxDensity max (list max [particleDensity] of patches  max [antiParticleDensity] of patches)
;  ask patches [ifelse particleDensity > antiParticleDensity
;    [set pcolor scale-color blue particleDensity 0 maxDensity]
;    [set pcolor scale-color red antiparticleDensity 0 maxDensity]
;  ]
;
;end

to set-shapes
   set-default-shape quarks "circle"
  set-default-shape antiquarks "circle 2"
  set-default-shape neutrinos "square"
  set-default-shape antineutrinos "square 2"
  set-default-shape electrons "triangle"
  set-default-shape positrons "triangle 2"
  set-default-shape photons "star"
end

to visualize-space-time
  let yScale max (list max-pycor ticks) / max-pycor
  ask turtles [set ycor birthTick / yScale]
end

to-report regress-exponential [data-list indep-var]
 set data-list  (map [x -> log x 10] data-list)
 report  matrix:regress matrix:from-column-list (list data-list indep-var)
end

to-report regress-power [data-list indep-var]
  set data-list  (map [x -> log x 10] data-list)
  set indep-var  (map [x -> log x 10] indep-var)
  report  matrix:regress matrix:from-column-list (list data-list indep-var)
end


to fitTrendlines
  set-current-plot "semi-log measurements"
  set-current-plot-pen "trendline" plot-pen-reset
  let fit regress-exponential measurementsList measurementsTicksList
  let expConstant item 0 (item 0 fit)
  set expRSquared item 0 (item 1 fit)
  set expSlope item 1 (item 0 fit)
  plotxy 0 expConstant  plotxy ticks expSlope * ticks + expConstant

  set-current-plot "log/log measurements"
  set-current-plot-pen "trendline" plot-pen-reset
  set fit regress-power measurementsList measurementsTicksList
  let powerConstant item 0 (item 0 fit)
  set powerRSquared item 0 (item 1 fit)
  set powerSlope item 1 (item 0 fit)
  plotxy 0 powerConstant  plotxy log ticks 10 powerSlope * log ticks 10 + powerConstant
end


;-------------helper functions

to-report fermionDensity
  ifelse totalMeasurements = 0
    [report 0]
    [report (totalFermionsAndLeptons / totalMeasurements)]
end

to-report energyDensity
  ifelse totalMeasurements = 0
    [report 0]
    [report (totalEnergy / totalMeasurements)]
end

to-report totalEnergy
  report sum [energy] of photons
end

to-report totalFermionsAndLeptons
  report count (turtle-set quarks antiquarks electrons positrons neutrinos antineutrinos electrons positrons)
end

to measurements-inc
  set totalMeasurements totalMeasurements + 1
end

to lifetime-inc
  set old? true
  ifelse finiteLifetime?
    [set lifetime lifetime + HBoxT * LifetimeExtension]
    [set lifetime maxInteger]
  if increaseTwin? [
    ask link-neighbors [
      ifelse finiteLifetime?
    [set lifetime lifetime + HBoxT * LifetimeExtension]
    [set lifetime maxInteger]
    ]
  ]


end

to shift-color
  if breed = quarks     [set color item (((position color [red green blue])      + 1) mod 3) [red green blue] ]
  if breed = antiquarks [set color item (((position color [cyan magenta yellow]) + 1) mod 3) [cyan magenta yellow] ]
end

to nb
  ;enforce H=I
  ;CRUX implement g
end
@#$#@#$#@
GRAPHICS-WINDOW
1030
315
1443
729
-1
-1
6.231
1
10
1
1
1
0
0
0
1
0
64
0
64
1
1
1
ticks
30.0

BUTTON
15
40
78
73
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
83
40
143
73
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
1025
190
1240
223
HBoxT
HBoxT
1
10
2.0
1
1
dE X dT
HORIZONTAL

SLIDER
1135
820
1370
853
k
k
0
4
1.0
.01
1
NIL
HORIZONTAL

SLIDER
1136
854
1371
887
resting-length
resting-length
0
4
0.77
.01
1
NIL
HORIZONTAL

SLIDER
1135
890
1370
923
repulsion
repulsion
0
10
1.5
.1
1
NIL
HORIZONTAL

SLIDER
1025
120
1240
153
LifetimeExtension
LifetimeExtension
1
20
17.2
.01
1
NIL
HORIZONTAL

SLIDER
1025
155
1240
188
MeanCreationRate
MeanCreationRate
0
30
3.0
1
1
NIL
HORIZONTAL

PLOT
220
105
620
280
Total Measurements (Space Creation)
time
measurements
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"measurments" 1.0 0 -13840069 true "" "plot  totalMeasurements "

MONITOR
1030
270
1105
315
total
count turtles
17
1
11

PLOT
620
105
935
280
Particle Population
time
population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"quarks" 1.0 0 -2674135 true "" "plot count quarks"
"antiquarks" 1.0 0 -11221820 true "" "plot count antiquarks"

SLIDER
1135
925
1370
958
repeatLayout
repeatLayout
1
50
9.0
1
1
NIL
HORIZONTAL

SWITCH
1135
785
1268
818
layout-space?
layout-space?
1
1
-1000

SWITCH
1385
785
1557
818
VisualizeFieldDensity?
VisualizeFieldDensity?
1
1
-1000

SLIDER
1385
821
1557
854
fieldDiffuseAmount
fieldDiffuseAmount
0
100
14.0
1
1
NIL
HORIZONTAL

SLIDER
1135
960
1350
993
K
K
0
1
1.0
.01
1
NIL
HORIZONTAL

SWITCH
1400
893
1597
926
acceleratedRandomWalk?
acceleratedRandomWalk?
1
1
-1000

SLIDER
225
40
430
73
randomSeed
randomSeed
1
10000
3.0
1
1
NIL
HORIZONTAL

MONITOR
935
100
1010
145
quarks
count quarks
17
1
11

MONITOR
935
145
1010
190
antiquarks
count antiquarks
17
1
11

PLOT
220
280
420
450
log/log Measurements
log ticks
log measurements
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"measurements" 1.0 0 -13840069 true "" "if totalMeasurements > 0 [plotxy log ticks 10 log totalMeasurements 10]"
"trendline" 1.0 0 -7500403 true "" ""

PLOT
420
280
620
450
semi-log measurements
ticks
log Measurements
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"measurements" 1.0 0 -13840069 true "" "if totalMeasurements > 0 [plotxy ticks log totalMeasurements 10]"
"trendline" 1.0 0 -2674135 true "" ""

SLIDER
15
105
220
138
R
R
0
1
0.1
.01
1
q-aq transformation
HORIZONTAL

SLIDER
10
435
215
468
L
L
0
1
0.26
.01
1
photons - > elec positron
HORIZONTAL

SLIDER
10
330
215
363
A
A
0
1
1.0
.01
1
annihilate**>  color
HORIZONTAL

SLIDER
10
365
215
398
B
B
0
1
1.0
.01
1
quark color create
HORIZONTAL

SLIDER
10
295
215
328
C
C
0
1
1.0
.01
1
photons-> q-aq
HORIZONTAL

SLIDER
1273
70
1478
103
G
G
0
1
1.0
.01
1
quark antiquark
HORIZONTAL

SLIDER
1273
140
1478
173
H
H
0
1
1.0
.01
1
neutrino positron
HORIZONTAL

SLIDER
1273
176
1478
209
I
I
0
1
1.0
.01
1
electron antineutrino
HORIZONTAL

SLIDER
10
400
215
433
K
K
0
1
1.0
.01
1
positron electron annihilation
HORIZONTAL

SLIDER
1395
858
1570
891
S
S
0
1
0.55
.001
1
NIL
HORIZONTAL

TEXTBOX
1273
50
1423
81
Particles from Vacuum
14
0.0
1

TEXTBOX
15
85
165
103
Measurements
14
0.0
1

SWITCH
1025
50
1160
83
finiteLifetime?
finiteLifetime?
0
1
-1000

SWITCH
1025
85
1160
118
increaseTwin?
increaseTwin?
0
1
-1000

PLOT
620
630
935
815
Total Energy (of photons)
time
total energy
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot totalEnergy"

SLIDER
15
140
220
173
RM
RM
0
1
0.95
.01
1
NIL
HORIZONTAL

SLIDER
1273
106
1478
139
singlePair
singlePair
0
1
1.0
.01
1
single q-aq
HORIZONTAL

PLOT
621
280
936
450
population electrons positrons
time
population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"electrons" 1.0 0 -5204280 true "" "plot count electrons"
"positrons" 1.0 0 -11783835 true "" "plot count positrons"

PLOT
621
450
936
630
population neutrinos antineutrinos
time
population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"neutrinos" 1.0 0 -817084 true "" "plot count neutrinos"
"anitneutrinos" 1.0 0 -10146808 true "" "plot count antineutrinos"

BUTTON
430
40
525
73
random universe
set randomSeed random 10000
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
935
630
1010
675
photons
count photons
17
1
11

SLIDER
15
175
220
208
newParticleInfluence
newParticleInfluence
0
1
0.0
.01
1
NIL
HORIZONTAL

MONITOR
935
450
1010
495
neutrinos
count neutrinos
17
1
11

MONITOR
935
495
1010
540
antineutrinos
count antineutrinos
17
1
11

MONITOR
935
280
1010
325
electrons
count electrons
17
1
11

MONITOR
935
325
1010
370
positrons
count positrons
17
1
11

SWITCH
525
40
657
73
autoRandom?
autoRandom?
1
1
-1000

SWITCH
1280
280
1442
313
visualizeSpaceTime?
visualizeSpaceTime?
0
1
-1000

SLIDER
15
210
187
243
numPhotonsCreated
numPhotonsCreated
0
4
2.0
1
1
NIL
HORIZONTAL

SLIDER
15
240
187
273
numPhotonsRequired
numPhotonsRequired
1
3
2.0
1
1
NIL
HORIZONTAL

SLIDER
10
510
215
543
M
M
0
1
0.09
.01
1
NIL
HORIZONTAL

SLIDER
10
545
215
578
N
N
0
1
0.07
.01
1
NIL
HORIZONTAL

SLIDER
10
580
215
613
O
O
0
1
0.07
.01
1
NIL
HORIZONTAL

SLIDER
10
615
215
648
P
P
0
1
0.08
.01
1
NIL
HORIZONTAL

MONITOR
875
35
932
80
version
version
17
1
11

SLIDER
1270
235
1480
268
proportionalCreation
proportionalCreation
0
.05
0.041
.001
1
percent
HORIZONTAL

SWITCH
1115
235
1270
268
useProportional?
useProportional?
1
1
-1000

BUTTON
390
450
475
495
Fit
fitTrendlines
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
475
450
542
495
NIL
expSlope
3
1
11

MONITOR
540
450
620
495
NIL
expRSquared
4
1
11

MONITOR
225
450
302
495
NIL
powerSlope
3
1
11

MONITOR
300
450
390
495
NIL
powerRSquared
4
1
11

PLOT
315
495
617
622
histogram photon energy
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" "if count photons > 0 [\n  ; set-plot-x-range ((min [energy] of photons) - 1) ((max [energy] of photons) + 1)\n  set-plot-x-range 10 6000\n  set-histogram-num-bars 100\n]"
PENS
"default" 1.0 1 -16777216 true "" "histogram [energy] of photons"

SWITCH
1480
175
1582
208
lockItoH?
lockItoH?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>totalMeasurements</metric>
    <metric>count particles</metric>
    <metric>count antiparticles</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="layout-space?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VisualizeFieldDensity?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repeatLayout">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repulsion">
      <value value="1.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="S" first="0.05" step="0.05" last="1"/>
    <enumeratedValueSet variable="K">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HBoxT">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resting-length">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RateOfMeasurement">
      <value value="64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceleratedRandomWalk?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LifetimeExtension">
      <value value="17.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MeanCreationRate">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fieldDiffuseAmount">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="k">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jan042020" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>fitTrendlines</final>
    <timeLimit steps="35"/>
    <exitCondition>count turtles &gt; 7000</exitCondition>
    <metric>count quarks</metric>
    <metric>count antiquarks</metric>
    <metric>count electrons</metric>
    <metric>count positrons</metric>
    <metric>count neutrinos</metric>
    <metric>count antineutrinos</metric>
    <metric>totalMeasurements</metric>
    <metric>powerSlope</metric>
    <metric>powerRSquared</metric>
    <metric>expSlope</metric>
    <metric>expRSquared</metric>
    <enumeratedValueSet variable="singlePair">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R">
      <value value="0"/>
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VisualizeFieldDensity?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockItoH?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repeatLayout">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="S">
      <value value="0.55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exponentialBase">
      <value value="2.71"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="K">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HBoxT">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resting-length">
      <value value="0.77"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="increaseTwin?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="L">
      <value value="0.26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="0.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fieldDiffuseAmount">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="useProportional?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="G" first="0" step="0.5" last="1"/>
    <steppedValueSet variable="H" first="0" step="0.5" last="1"/>
    <enumeratedValueSet variable="I">
      <value value="0.45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="autoRandom?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="A" first="0" step="0.5" last="1"/>
    <enumeratedValueSet variable="visualizeSpaceTime?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="B" first="0" step="0.5" last="1"/>
    <enumeratedValueSet variable="layout-space?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="C" first="0" step="0.5" last="1"/>
    <enumeratedValueSet variable="repulsion">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportionalCreation">
      <value value="0.041"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exponentialConstant">
      <value value="1.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="powerLawConstant">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="powerLawExponent">
      <value value="5.3308"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceleratedRandomWalk?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LifetimeExtension">
      <value value="17.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MeanCreationRate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RM">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numPhotonsRequired">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numPhotonsCreated">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="k">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="O">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="P">
      <value value="0.08"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="finiteLifetime?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="newParticleInfluence">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jan042020_2" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>fitTrendlines</final>
    <timeLimit steps="35"/>
    <exitCondition>count turtles &gt; 7000</exitCondition>
    <metric>count quarks</metric>
    <metric>count antiquarks</metric>
    <metric>count electrons</metric>
    <metric>count positrons</metric>
    <metric>count neutrinos</metric>
    <metric>count antineutrinos</metric>
    <metric>totalMeasurements</metric>
    <metric>powerSlope</metric>
    <metric>powerRSquared</metric>
    <metric>expSlope</metric>
    <metric>expRSquared</metric>
    <metric>timer</metric>
    <enumeratedValueSet variable="singlePair">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed">
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="R">
      <value value="0"/>
      <value value="0.01"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="VisualizeFieldDensity?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lockItoH?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repeatLayout">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="S">
      <value value="0.55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exponentialBase">
      <value value="2.71"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="K">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HBoxT">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resting-length">
      <value value="0.77"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="increaseTwin?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="L">
      <value value="0.26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M">
      <value value="0.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fieldDiffuseAmount">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="useProportional?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="G" first="0" step="0.5" last="1"/>
    <steppedValueSet variable="H" first="0" step="0.5" last="1"/>
    <enumeratedValueSet variable="I">
      <value value="0.45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="autoRandom?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="A" first="0" step="0.5" last="1"/>
    <enumeratedValueSet variable="visualizeSpaceTime?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="B" first="0" step="0.5" last="1"/>
    <enumeratedValueSet variable="layout-space?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="C" first="0" step="0.5" last="1"/>
    <enumeratedValueSet variable="repulsion">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportionalCreation">
      <value value="0.041"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exponentialConstant">
      <value value="1.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="powerLawConstant">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="powerLawExponent">
      <value value="5.3308"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acceleratedRandomWalk?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LifetimeExtension">
      <value value="17.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MeanCreationRate">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RM">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numPhotonsRequired">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numPhotonsCreated">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="k">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="O">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="P">
      <value value="0.08"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="finiteLifetime?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="newParticleInfluence">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
