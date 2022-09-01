xquery version "3.1";
import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "xmldb:exist:///db/apps/BetMasWeb/modules/queries.xqm";
import module namespace tl="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/timeline"at "xmldb:exist:///db/apps/BetMasWeb/modules/timeline.xqm";
import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "xmldb:exist:///db/apps/BetMas/modules/expand.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";


              (:  
              subst 
              del| add
              
              choice 
                   t:sic| t:corr 
                   t:orig|  t:reg
                
                expan
                t:abbr | t:ex 
                :)
                
(:                let $choicepar:= distinct-values($q:col//t:choice/child::t:*/name()):)
(:let $choicepar:= distinct-values($q:col//t:choice/parent::t:*/name())

persName
incipit
placeName
title
q
colophon
quote
explicit
date
ab
l
foreign
seg
del
add
desc
supplied
note
lem
occupation
:)

declare function local:optionsexpand($model, $bibliography){
element {$model/name()} {
$model/@*,
if($model/t:choice[t:corr][t:sic]) then
<choice><corr>{$model//t:corr/@resp}{
for $n in $model/node() return if ($n/self::t:choice) then expand:tei2fulltei($n/t:corr/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</corr>
<sic>{$model//t:sic/@resp}{for $n in $model/node() return if ($n/self::t:choice) then expand:tei2fulltei($n/t:sic/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</sic></choice>
else if ($model/t:choice[t:reg][t:orig]) then
<choice><reg>{$model//t:reg/@resp}{for $n in $model/node() return if ($n/self::t:choice) then expand:tei2fulltei($n/t:reg/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</reg>
<orig>{$model//t:orig/@resp}{for $n in $model/node() return if ($n/self::t:choice) then expand:tei2fulltei($n/t:orig/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</orig></choice>
else
<subst><del>{$model//t:del/@*}{for $n in $model/node() return if ($n/self::t:subst) then expand:tei2fulltei($n/t:del/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</del>
<add>{$model//t:add/@*}{for $n in $model/node() return if ($n/self::t:subst) then expand:tei2fulltei($n/t:add/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</add></subst>
}
};
let $bibliography:= <bibl></bibl>
let $model :=    <persName xmlns="http://www.tei-c.org/ns/1.0" role="owner" ref="PRS11648WalattaSerael">ወለተ፡ <choice>
                                    <sic resp="PRS10171Wright">ስ</sic>
                                    <corr resp="DR">እስ</corr>
                                 </choice>ራኤል፡</persName>
                                 return
                                 if($model[t:subst|t:choice]) then local:optionsexpand($model, $bibliography)
                                 else expand:tei2fulltei($model/node(), $bibliography)

