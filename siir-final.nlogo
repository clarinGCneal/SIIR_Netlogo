globals [ b2 c3 ]

turtles-own [;; Turtle characteristics
  infectious? ;; note: symptomatics have the virus but not infectious (since they're assumed to be quarantined)
  infection_state ;; presymptomatic, asymptomatic, symptomatic
  dead ;; is alive [true/false]
  immune ;; is immune [true / false] ;recovered or susceptible
  inc_p ; incubation period for presymptomatics ;at the end they bifurcates to either asymp or symp ;note:Since there's already a global variable 'incubation period', they can't be of the same name
  ons_p ; (onset period) symp or asymp at the end of this period, bifurcates to recovered or dead (if symp)
  antibody_duration ;; if not immune auto 0 else the inverse of the set antibody decay
  extra-perc ;; percentage of extravertedness
  extraversion-level ;; low, med, high
]

to setup ;; this procedure sets up the simulation for start
  clear-all

  set b2 1 - b1
  set c3 1 - c2

  create-turtles number_turtles [ setxy random-xcor random-ycor
    set infectious? false
    set infection_state "susceptible"
    set shape "person"
    set dead false
    set immune false
    set inc_p 0
    set ons_p 0
    set antibody_duration 0
    set extra-perc random-float 1
    if extra-perc > 0.50 and extra-perc < 0.63 [set extraversion-level "Med"]
    if extra-perc < 0.50 [set extraversion-level "Low"]
    if extra-perc > 0.63 [set extraversion-level "High"]
  ]

  ask one-of turtles [
    set infectious? true
    set infection_state "presymptomatic"
    set inc_p incubation_period
    set extraversion-level "High"
    ;set infection_state "asymptomatic"
    ;set ons_p onset_period
  ] ;;one gets infected

  ask turtles [recolor]

  reset-ticks
end

to go ;; each tick of simulation turtle do this
  if all? turtles [infectious?] [stop]
  if all? turtles [infectious? = false] [stop]

  ask turtles [move]
  ask turtles [spread]
  ask turtles [transform]
  ask turtles [recover]
  ask turtles [recolor]

  tick
end

to move
  if dead = false and infection_state != "symptomatic" ;at the simplest form, symptomatics won't move since they're assumed to be quarantined
  [                                                    ;ig better if there are specific patches that is either their home or the hospital to be quarantined in (future endeavor)
    if extraversion-level = "High" [set heading (towards one-of neighbors) move-to one-of neighbors if any? other turtles-here with [dead] [move-to one-of neighbors] ]
   if extraversion-level = "Med" [right random 150 left random 150 fd 1]
   if extraversion-level = "Low" [if any? other turtles-here with [not dead] or not any? turtles-here in-radius 1 with [not dead] [right random 150 left random 150 fd 1]]
  ]
end

to spread
  ifelse infection_state != "susceptible" [] [
    if any? other turtles-here in-radius 1 with [infectious?]
    [
      if immune = false
      [
        if random-float 1.0 < infection_rate
        [
          set infectious? true
          set infection_state "presymptomatic"
          set inc_p incubation_period
          if connection [
            ask self [create-links-from other turtles-here with [infectious?]]
          ]
        ]
      ]
    ] ;; checking if there is virus near this agent
  ]

end

to transform ;change states

  ;presymptomatic bifurcation
  ;presymptomatic to symptomatic - b1 ;presymptomatic to asymptomatic - b2
  if infection_state = "presymptomatic" and infectious? = true
  [
    ifelse inc_p = 0 [
      if b1 > b2
      [
        ifelse random-float 1 < b1
        [ set infection_state "symptomatic" set infectious? false set ons_p onset_period]
        [ set infection_state "asymptomatic" set ons_p onset_period]
      ]
      if b2 > b1
      [
        ifelse random-float 1 < b2
        [ set infection_state "asymptomatic" set ons_p onset_period]
        [ set infection_state "symptomatic" set infectious? false set ons_p onset_period]
      ]
      if b2 = b1
      [
        ifelse random-float 1.0 < 0.5
        [ set infection_state "symptomatic" set infectious? false set ons_p onset_period]
        [ set infection_state "asymptomatic" set ons_p onset_period]
      ]
    ] [ set inc_p inc_p - 1 ]
  ]

  ;recovered goes back to susceptible after some time
  if infection_state = "recovered" and infectious? = false and immune = true
  [
    ifelse antibody_duration = 0 [
      set infection_state "susceptible" set immune false
    ] [ set antibody_duration antibody_duration - 1]
  ]

end

to recover ;symptomatic to recover or death? ;asymptomatic to recover?

  if infection_state = "asymptomatic" and infectious? = true
  [
    ifelse ons_p = 0
    [
      set infection_state "recovered" set infectious? false set immune true set antibody_duration 1 / antibody_decay
    ][ set ons_p ons_p - 1]
  ]

  if infection_state = "symptomatic" and infectious? = false
  [
    ;either death or recovery
    ifelse ons_p = 0
    [
      if c2 > c3
      [
        ifelse random-float 1 < c2
        [ set infection_state "recovered" set infectious? false set immune true set antibody_duration 1 / antibody_decay]
        [ set infection_state "dead" set dead true ]
      ]
      if c3 > c2
      [
        ifelse random-float 1 < c3
        [ set infection_state "dead" set dead true]
        [ set infection_state "recovered" set infectious? false set immune true set antibody_duration 1 / antibody_decay]
      ]
      if c2 = c3
      [
        ifelse random-float 1.0 < 0.5
        [ set infection_state "recovered" set infectious? false set immune true set antibody_duration 1 / antibody_decay]
        [ set infection_state "dead" set dead true]
      ]
    ][ set ons_p ons_p - 1]
  ]

end

to recolor ;green-susceptible ;yellow-presymptomatic ;red-asymptomatic ;violet-symptomatic ;blue-recovered ;black-dead
  if infectious? = false and infection_state = "susceptible" [set color gray + 1]
  if infectious? and infection_state = "presymptomatic" [set color yellow]
  if infectious? and infection_state = "asymptomatic" [set color red]
  if infectious? = false and infection_state = "symptomatic" [set color violet]
  if immune [set color blue]
  if dead [set color black]
end

;;;;;;;;;;;;;

to-report b2-value
  report 1 - b1
end

to-report c3-value
  report 1 - c2
end

to-report antibody-duration
  report 1 / antibody_decay
end

;;;;;;;;;;;;;

to-report susceptible
  report count turtles with [infection_state = "susceptible"]
end

to-report presymptomatic
  report count turtles with [infection_state = "presymptomatic"]
end

to-report asymptomatic
  report count turtles with [infection_state = "asymptomatic"]
end

to-report symptomatic
  report count turtles with [infection_state = "symptomatic"]
end

to-report recovered
  report count turtles with [immune = true]
end

to-report deceased
  report count turtles with [dead = true]
end

to-report extraverted
  report count turtles with [extraversion-level = "High"]
end

to-report ambiverted
  report count turtles with [extraversion-level = "Med"]
end

to-report introverted
  report count turtles with [extraversion-level = "Low"]
end
@#$#@#$#@
GRAPHICS-WINDOW
1034
17
2028
1012
-1
-1
11.53
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks
30.0

BUTTON
28
40
91
73
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
92
40
155
73
start
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
160
40
276
73
connection
connection
0
1
-1000

SLIDER
280
40
592
73
number_turtles
number_turtles
0
5000
5000.0
1
1
NIL
HORIZONTAL

SLIDER
28
81
200
114
infection_rate
infection_rate
0
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
205
81
377
114
antibody_decay
antibody_decay
0
1
0.03
.001
1
NIL
HORIZONTAL

PLOT
12
265
1029
704
plot 1
days
number of people
0.0
200.0
0.0
100.0
true
true
"" ""
PENS
"susceptible" 1.0 0 -5987164 true "" "plot susceptible"
"presymptomatic" 1.0 0 -1184463 true "" "plot presymptomatic"
"asymptomatic" 1.0 0 -2674135 true "" "plot asymptomatic"
"symptomatic" 1.0 0 -8630108 true "" "plot symptomatic"
"recovered" 1.0 0 -13791810 true "" "plot recovered"
"dead" 1.0 0 -16777216 true "" "plot deceased"

MONITOR
927
395
1017
440
#susceptible
susceptible
17
1
11

MONITOR
927
444
1017
489
#presymptomatic
presymptomatic
17
1
11

MONITOR
927
494
1017
539
#asymptomatic
asymptomatic
17
1
11

MONITOR
927
544
1017
589
#symptomatic
symptomatic
17
1
11

MONITOR
927
595
1018
640
#recovered
recovered
17
1
11

MONITOR
927
645
1018
690
#dead
deceased
17
1
11

INPUTBOX
28
121
114
181
incubation_period
5.0
1
0
Number

INPUTBOX
121
121
207
181
onset_period
17.0
1
0
Number

PLOT
12
707
212
857
susceptible
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -7500403 true "" "plot susceptible"

PLOT
15
862
215
1012
presymptomatic
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -1184463 true "" "plot presymptomatic"

PLOT
219
862
419
1012
asymptomatic
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot asymptomatic"

PLOT
422
862
622
1012
symptomatic
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -8630108 true "" "plot symptomatic"

PLOT
219
707
419
857
recovered
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot recovered"

PLOT
422
707
622
857
dead
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot deceased"

PLOT
625
707
1029
859
susceptible_recovered
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -5987164 true "" "plot susceptible"
"pen-1" 1.0 0 -13791810 true "" "plot recovered"

PLOT
625
864
1027
1014
pre_asymp_symp_dead
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot deceased"
"pen-1" 1.0 0 -1184463 true "" "plot presymptomatic"
"pen-2" 1.0 0 -2674135 true "" "plot asymptomatic"
"pen-3" 1.0 0 -8630108 true "" "plot symptomatic"

INPUTBOX
216
121
330
181
antibody_decay
0.03
1
0
Number

INPUTBOX
338
121
395
181
b1
0.3
1
0
Number

MONITOR
400
121
457
166
b2
b2-value
3
1
11

TEXTBOX
467
120
617
176
b1 is the symptomatic\nprobability, whilst\nb2 is the asymptomatic\nprobability
11
0.0
1

INPUTBOX
338
187
396
247
c2
0.8
1
0
Number

MONITOR
400
187
460
232
NIL
c3-value
3
1
11

TEXTBOX
468
190
618
232
c2 is the recovery\nprobability, whilst\nc3 is the death probability
11
0.0
1

MONITOR
216
191
328
236
antibody-duration
antibody-duration
12
1
11

MONITOR
789
217
869
262
NIL
extraverted
17
1
11

MONITOR
872
217
951
262
NIL
ambiverted
17
1
11

MONITOR
952
217
1027
262
NIL
introverted
17
1
11

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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
0
@#$#@#$#@
