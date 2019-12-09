# NISP

*Scheme dialect livecoding tracker for norns*

**Work in progress. Everything is subject to change** 


### Controls

**`~`**|`open / close repl`

**`shift + ctrl`**|`start / stop playback`

**`shift + 1 - 4`**|`mute track`

**`enter`**|`open text editor (third column of track must be selected)`

**`esc`**|`close text editor`

**`shift + enter`**|`save expression in cell (while in text edit mode)`

**`ctrl + c / v`**|`copy / paste`

**`shift + esc`**|`open / close norns menu`

**`ctrl + left / right`**|`switch tabs`

**`shift + up / down`**|`fast nav between samples in params menu`


### Commands

| function     |       arguments         |  description                                                
|:-------------|:------------------------|:-----------------------------------------------------------
| `(def)`      | `symbol, value`         | define a symbol                                             | 
| `(lambda)`   | `args, function`        | anonymous function                                          |
| `(quote)` `'`| `expr`                  | returns unevaluated expression                              |
| `(if)`       | `cond, expr 1, expr 2`  | evaluate expr 1 if conf is true, else evaluates expr 2      |  
| `(@)`        | `track`  *<sup>optional*| returns current position                                    |
| `(bpm)`      | `value`                 | set global bpm                                              |       
| `(jmp)`      | `pos`                   | jump to position                                            |
| `(skip)`     | `pos`                   | skip current step                                           |               
| `(ever)`     | `N, expr`               | evaluate expression every **N** cycle                       |              
| `(mute)`     | `track` *<sup>optional* | mute track                                                  |             
| `(sync)`     | `track` *<sup>optional* | sync positions to track, or to global pos                   |            
| `(save)`     | `id`                    | save pattern                                                |           
| `(load)`     | `id`                    | load pattern                                                |          
| `(note)`     | `value`                 | write note at current position                              |
| `(sample)`   | `value`                 | write sample at current position                            |
| `(pos)`      | `value`                 | set position of current sample                              |
| `(param)`    | `value`                 | set current sample [param](#extras)                         |
| `(help)`     |   -                     | display help                                                |

###### Math
`(+)`  `(-)` `(*)` `(/)` `(%)`  `(^)` `(=)` `(eq)` `(>)` `(<)` `(<=)` `(>=)` `(rnd)`
###### Other
`(list)` `(list?)` `(append)` `(apply)` `(begin)` `(car)` `(cdr)` `(cons)` 
`(len)` `(get)`  `(put)`  `(nil?)` `(num?)` `(print)` `(concat)` `(map)` `(#t)` `(#f)`


##### Examples
*<sup>Functions can be executed either live in repl or from pattern cells.*

 ```common-lisp

(def A 1) - sets symbol A to 1

(print "Hello") - double quotes for strings

(def A (lambda () (print "Hello"))) - defines a function (A) with no arguments

(def A (lambda (a b c) (+ a b c))) - defines a function (A) which takes 3 arguments and returns their sum.

(get '(1 2 3 4) 1) - returns first element from list

(bpm 120) - set bpm to 120

(jmp 0) - set current track position to the very beginning

(pos (rnd 1 99)) - set random start position for current sample

(atk 0.25) - set current sample attack to 0.25
```
<br>

###### Extras
<sup>[more about scheme](http://www.shido.info/lisp/idx_scm_e.html)

<details>
 <summary>params shortenings</summary>

    atk  - amp_env_attack
    dec - amp_env_decay
    sus - amp_env_sustain
    rel - amp_env_release
    detune - detune_cents
    strtch - by_percentage
    ctf - filter_freq
    res - filter_resonance
    ftype - filter_type
    qlt - quality
    fm-lfo1 - freq_mod_lfo_1
    fm-lfo2 - freq_mod_lfo_2
    f-lfo1 - filter_freq_mod_lfo_1
    f-lfo2 - filter_freq_mod_lfo_2
    p-lfo1 - pan_mod_lfo_1
    p-lfo2 - pan_mod_lfo_2
    a-lfo1 - amp_mod_lfo_1 
    a-lfo2 - amp_mod_lfo_2
    fm-env - freq_mod_env
    f-fm-env - filter_freq_mod_env
    f-fm-vel - filter_freq_mod_vel
    f-fm-pr - filter_freq_mod_pressure
    f-track - filter_tracking
    p-env - pan_mod_env
    m-atk - mod_env_attack
    m-dec - mod_env_decay 
    m-sus - mod_env_sustain
    m-rel - mod_env_release

</details> 



<br>


###### <sup>Known bugs-features:

<sup>copy-pasted expression cells are linked, so editing one would affect all others.

