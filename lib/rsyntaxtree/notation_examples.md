RSyntaxTree examples: 76 trees, every one verified to draw.

Each is the input behind a figure in the gallery at https://yohasebe.github.io/rsyntaxtree/examples.
The settings line names the options the gallery records for that figure;
anything not named is at its default. The test suite runs every input
here through the same parser that draws it, so each one is accepted.

Notation reference: rsyntaxtree --notation
Check an input without drawing: rsyntaxtree --validate "[S [NP a] [VP b]]"

What the option names on a settings line mean: one line each at the end
of the reference (`rsyntaxtree --notation`), the full story in the manual
at https://yohasebe.github.io/rsyntaxtree/documentation. Everything at once, this file and the manual
together: https://yohasebe.github.io/rsyntaxtree/llms-full.txt


## 000 — RSyntaxTree basic example

Category: General
Settings: fontstyle=noto-sans tidy=low

```
[S
  [NP |R| **SyntaxTree**]
  [VP
    [V *generates*]
    [NP
      [Adj #\+multilingual\
            \+beautiful]
      [NP ^syntax\
           trees]
    ]
  ]
]
```

## 001 — Basic binary tree

Category: General
Settings: fontstyle=noto-serif tidy=low vheight=1.0

```
[A
  [B
    [D]
    [E]
  ]
  [C
    [F]
    [G]
  ]
]
```

## 002 — Minimalistic syntree

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif tidy=medium vheight=1.5
Source: Chomsky 1995: 50

```
[CP
  [John]
  [TP
    [T
      [V
        [cause]
        [V fall]
      ]
      [T]
    ]
    [VP
      [V *t*_c_]
      [CP
        [books]
        [*t*_f_]
      ]
    ]
  ]
]
```

## 003 — Minimalistic syntree

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif tidy=low vheight=1.5
Source: Chomsky 1995: 62

```
[VP
  [John]
  [V'
    [V *e*]
    [VP
      [NP a book]
      [V'
        [V gave]
        [to\-Bill]
      ]
    ]
  ]
]
```

## 004 — Minimalistic syntree

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif tidy=low vheight=1.5
Source: Chomsky 1995: 180

```
[VP_1_
  [NP_1_ John]
  [V'_1_
    [V_1_ *e*]
    [VP_2_
      [NP_2_ the book]
      [V'_2_
        [V_2_ put]
        [ZP on the shelf]
      ]
    ]
  ]
]
```

## 005 — Minimalistic syntree

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif leafstyle=nothing tidy=low vheight=1.5
Source: Chomsky 1995: 355

```
[X__max__
  [\[Y\−X\]]
  [YP
    [Spec_1_]
    [Y'
      [*t*]
      [ZP]
    ]
  ]
]
```

## 006 — Minimalistic syntree

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif leafstyle=nothing tidy=low vheight=1.5
Source: Chomsky 1995: 369

```
[𝑣P
  [Spec_2_]
  [𝑣'
    [Subj]
    [𝑣'
      [Vb]
      [VP
        [*t*_v_]
        [Obj]
      ]
    ]
  ]
]
```

## 007 — X-bar model (with Japanese labels)

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif leafstyle=bar tidy=low

```
[XP
  [W Specifier\
     指定部]
  [X'
    [X'
      [X Head\
         主要部]
      [Y Complement\
         補部]
    ]
    [Z Modifier\
       付加部]
  ]
]
```

## 008 — vP-shell (Japanese)

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif hspacing=1.5 tidy=medium vheight=1.2

```
[𝑣P
  [NP 太郎が]
  [𝑣'
    [VP
      [𝑣P
        [NP ^泥棒に]
        [𝑣'
          [VP ^財布を盗む]
          [𝑣]
        ]
      ]
      [V られ]
    ]
    [𝑣]
  ]
]
```

## 009 — Non-binary tree sample

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif tidy=low

```
[S__＊__
  [NP α_1_]
  [INFL (AGR)]
  [VP
    [V]
    [NP α_2_]
    [PP
      [P]
      [NP α_3_]
    ]
  ]
]
```

## 010 — vP-shell with movement paths

Category: Generative Grammar
Settings: fontstyle=noto-serif leafstyle=nothing tidy=low vheight=1.2
Source: Radford 2004

```
[CP
  [C
   ø]
  [TP
    [PRN
    **They**+>2
    ]
    [T'
      [T
       Will
      ]
      [vP
        [PRN
         ~**they**~+2
        ] 
        [v'
          [v
           ø<>\+<>*get*+>1
          ]
          [VP
            [DP
             the<>teacher]
            [V'
              [V
               ~*get*~+1
              ]
              [QP
               a<>present
              ]
            ]
          ]
        ]  
      ]
    ]
  ]
]
```

## 011 — CCG derivation: forward and backward application

Category: Combinatory Categorial Grammar
Settings: color=none derivation=on direction=btt fontstyle=noto-serif hspacing=2.0 leafstyle=nothing tidy=low vheight=0.5
Source: Steedman 2000

```
[S\t<
  [NP\t>
    [NP/N the]
    [N dog]]
  [S\\NP\t>
    [(S\\NP)/NP bit]
    [NP John]]]
```

## 012 — CCG derivation: a relative clause

Category: Combinatory Categorial Grammar
Settings: color=none derivation=on direction=btt fontstyle=noto-serif hspacing=2.0 leafstyle=nothing tidy=low vheight=0.5
Source: Steedman 2000

```
[NP\t>
  [NP/N the]
  [N\t<
    [N man]
    [N\\N\t>
      [(N\\N)/(S/NP) that]
      [S/NP\t>B
        [S/(S\\NP)\t>T
          [NP Mary]]
        [(S\\NP)/NP saw]]]]]
```

## 013 — HPSG sample

Category: Head-Driven Phrase Structure Grammar
Settings: color=none fontstyle=noto-serif leafstyle=bar linewidth=0.5 tidy=low vheight=1.5

```
[#*phrase*\
  HEAD\t|1|\
  SPR\t⟨<>⟩\
  COMPS\t⟨<>⟩
  [#*word*\
    HEAD\t|2|<>*noun*\
    SPR\t⟨<>⟩\
    COMPS\t⟨<>⟩
    Kim
  ]
  [#*phrase*\
    HEAD\t|1|\
    SPR\t⟨<>|2|<>⟩\
    COMPS\t⟨<>⟩
    [#*word*\
      HEAD\t|1|<>*verb*\
      SPR\t⟨<>|2|<>NP⟩\
      COMPS\t⟨<>|3|<>PP\[*on*\]⟩
      relies
    ]
    [#|3|<>*phrase*\
      HEAD\t|4|\
      SPR\t⟨<>⟩\
      COMPS\t⟨<>⟩
      [#*word*\
        HEAD\t|4|<>*prep*\
        FORM\t*on*\
        SPR\t⟨<>⟩\
        COMPS\t⟨<>|5|<>⟩
        on
      ]
      [#|5|<>*word*\
        HEAD\t*noun*\
        SPR\t⟨<>⟩\
        COMPS\t⟨<>⟩
        Sandy
      ]
    ]
  ]
]
```

## 014 — Cognitive Grammar sample

Category: Cognitive Grammar
Settings: color=none fontstyle=noto-serif vheight=1.0

```
[##*{👧}**--**|s|*\
  __|G|__<>RELATION\
  ---\
  *that<>girl<>is<>smart*
  [##*{👧}*\
    __|G|__<>THING\
    ---\
    *that<>girl*
    [##*{/}*\
     __|G|__<>THING\
     ----\
     *that*
    ]
    [##*{👧}*\
     THING\
     ----\
     *girl*
    ]
  ]
  [##{/}*--**|s|*\
   __|G|__<>RELATION\
   ---\
   *is<>smart*
    [##{/}*--*|/|\
      __|G|__<>RELATION\
      ---\
      *is*
    ]
    [##{/}--*|s|*\
      RELATION\
      ---\
      *smart*
    ]
  ]
]
```

## 015 — Phonology sample

Category: Phonology
Settings: fontstyle=noto-sans tidy=symmetric

```
[σ
  [Onset
    [s]
    [t]
    [r]
  ]
  [Rhyme
    [Nucleus ɛ]
    [Coda
      [ŋ]
      [k]
    ]
  ]
  [Appendix
    [θ]
    [S]
  ]
]
```

## 016 — Tic-tac-toe

Category: Miscellaneous
Settings: color=none fontstyle=noto-sans leafstyle=bar tidy=low vheight=1.5

```
[
  |○|||||\
  |×||×||○|\
  |×||○|||
  [
    |○|*|○|*||\
    |×||×||○|\
    |×||○|||
    [
      |○||○|*|×|*\
      |×||×||○|\
      |×||○|||
    ]
    [
      |○||○|||\
      |×||×||○|\
      |×||○|*|×|*
      [
        |○||○|*|○|*\
        |×||×||○|\
        |×||○||×|
      ]
    ]
  ]
  [
    |○|||*|○|*\
    |×||×||○|\
    |×||○|||
    [
      |○|*|×|*|○|\
      |×||×||○|\
      |×||○|||
      [
        |○||×||○|\
        |×||×||○|\
        |×||○|*|○|*
      ]
    ]
    [
      |○||||○|\
      |×||×||○|\
      |×||○|*|×|*
      [
        |○|*|○|*|○|\
        |×||×||○|\
        |×||○||×|
      ]
    ]
  ]
  [
    |○|||||\
    |×||×||○|\
    |×||○|*|○|*
    [
      |○|*|×|*||\
      |×||×||○|\
      |×||○||○|
      [
        |○||×|*|○|*\
        |×||×||○|\
        |×||○||○|
      ]
    ]
    [
      |○|||*|×|*\
      |×||×||○|\
      |×||○||○|
    ]
  ]
]
```

## 017 — Basic polyline sample

Category: General
Settings: fontstyle=noto-serif polyline=on tidy=low vheight=1.0

```
[A
  [B
    [D [H] [I]]
    [E [J] [K]]
  ]
  [C
    [F [L] [M]]
    [G [N] [O]]
  ]
]
```

## 018 — Tree with text labels in bold

Category: Generative Grammar
Settings: fontstyle=noto-serif tidy=low vheight=1.0
Source: Langacker 1969: 175

```
[S
  [NP I]
  [PdP
    [VP
      [V knew]
      [NP **Harvey**]      
    ]
    [Adv
      [when]
      [S
        [NP **Harvey**]
        [PdP was a little boy]
      ]
    ]
  ]
]
```

## 019 — Programming language parser

Category: Computer Science
Settings: color=none fontstyle=noto-sans-mono leafstyle=bar polyline=on tidy=low vheight=1.5
Source: Stuart 2014

```
[##\<statement\>
  [##\<while\>
    [##<>w<>]
    [##<>(<>]
    [##\<expression\>
      [##\<less\-than\>
        [##\<multiply\>
          [##\<term\>
            [##<>v<>]
          ]       
        ]
        [##<>\<<>]
        [##\<less\-than\>
          [##\<multiply\>
            [##\<term\>
              [##<>n<>]
            ]            
          ]
        ]        
      ]
    ]
    [##<>)<>]
    [##<>\{<>]
    [##\<statement\>
      [##\<assign\>
        [##<>v<>]
        [##<>\=<>]
        [##\<\expression\>
          [##\<less\-than\>
            [##\<multiply\>
              [##\<term\>
                [##<>v<>]
              ]
              [##<>\*<>]
              [##\<multiply\>
                [##\<term\>
                  [##<>n<>]
                ]
              ]  
            ]
          ]
        ]
      ]
    ]
    [##<>\}<>]
  ]
]
```

## 020 — From phoneme to sentence

Category: General
Settings: fontstyle=noto-sans leafstyle=bar tidy=low

```
[The<>umpires<>talked<>to<>the<>players
  [the<>umpires
    [the
      [<> ði]
    ]
    [umpires
      [umpire ʌ́mpaɪər]
      [s z]
    ]
  ]
  [talked<>to<>the<>players
    [talked
      [talk tɔːk]
      [ed t]
    ]
    [to
      [<> tə]
    ]
    [the
      [<> ðə]
    ]
    [players
      [player pléɪər]
      [s z]
    ]
  ]
]
```

## 021 — Types of meaning

Category: Pragmatics
Settings: color=none fontstyle=noto-serif leafstyle=bar polyline=on tidy=low vheight=1.5
Source: Zufferey, Moeschler, and Reboul 2014

```
[Types<>of<>meaning
  [conventional
    [semantic
      [entailment]
      [presupposition]
    ]
    [pragmatic
      [conventional\
       implicature]
    ]
  ]
  [non\-conventional
    [explicit
      [explicature]
    ]
    [implicit
      [conventional
        [generalized\
         implicature]
        [particularized\
         implicature]
      ]
      [non\-\
       conventional
        [pragmatic\
         presupposition]
      ]
    ]
  ]
]
```

## 022 — Arithmetic parser

Category: Computer Science
Settings: color=none fontstyle=noto-sans-mono leafstyle=bar polyline=on tidy=low vheight=1.0

```
[\<expression\>
  [\<term\>
    [\<term\>
      [\<factor\>
        \(
        [\<expression\>
          [\<expression\>
            [\<term\>
              [\<factor\>
                {A}
              ]
            ]
          ]
          [{＋}]
          [\<term\>
            [\<factor\>
              {B}
            ]
          ]
        ]
        \)
      ]
    ]
    [{＊}]
    [\<factor\>
      \(
      [\<expression\>
        [\<expression\>
          [\<term\>
            [\<factor\>
              {C}
            ]
          ]
        ]
        [{＋}]
        [\<term\>
          [\<factor\>
            {D}
          ]
        ]
      ]
      \)
    ]
  ]
]
```

## 023 — Tournament

Category: Miscellaneous
Settings: color=none fontstyle=noto-sans leafstyle=bar polyline=on tidy=low vheight=1.0

```
[{**D**}
  [{**D**}
    [A [{A}] [B]]
    [{**D**} [C] [{**D**}]]
  ]
  [G
    [F [E] [{F}]]
    [{G} [{G}] [H]]
  ]
]
```

## 024 — X-bar model

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif leafstyle=nothing tidy=high vheight=1.5

```
[XP
  [W Specifier]
  [X'
    [X'
      [X Head]
      [Y Complement]
    ]
    [Z Modifier]
  ]
]
```

## 025 — Network of non-prototypical sentence constructions

Category: Construction Grammar
Settings: color=none fontstyle=noto-serif leafstyle=bar polyline=on vheight=3.0
Source: Goldberg 2006: 177

```
[#**Non\-prototypical<>sentence**\
  ---\
  NON\-POSITIVE,\
  non\-predicate<>focus,\
  non\-assertive,\
  dependent,\
  non\-declarative
  [#**Y/N<>questions**\
    ---\
    NON\-POSITIVE,\
    non\-declarative\
    ---\
    *Did<>she<>go?*
    [#**Wh\-Questions**\
      ---\
      non\-declarative\
      ---\
      *Where<>did<>she<>go?*
    ]
    [#**Exclamatives**\
      ---\
      non\-assertive\
      ---\
      *Boy<>did<>she<>go!*
    ]
  ]
  [#**Counterfactual<>conditionals**\
    ---\
    NON\-POSITIVE\
    dependent,<>non\-asserted\
    ---\
    *Had<>he<>found<>a<>solution,<>he*\
    *would<>take<>time<>off<>and<>relax.*
  ]
  [#**Initial<>negative**\
    **adverb<>clauses**\
    ---\
    NON\-POSITIVE\
    ---\
    *Not<>until<>yesterday<>did*\
    *he<>take<>a<>break.*\
  ]
  [#**Negative<>rejoinder**\
    ---\
    NON\-POSITIVE,\
    dependent\
    ---\
    *Neither<>is<>this<>construction*\
    *unexpected.*
    [#**Positive<>conjunct<>clauses**\
      ---\
      non\-predicate<>focus,\
      dependent\
      ---\
      *So<>was<>I.*
    ]
  ]
  [#**Comparatives**\
    ---\
    non\-topic\-comment,\
    dependent\
    ---\
    *He<>was<>faster<>at<>it*\
    *than<>was<>she.*
  ]
  [#**Wishes,<>curses**\
    ---\
    NON\-POSITIVE,\
    non\-declarative\
    ---\
    *May<>a<>million<>flies*\
    *infest<>his<>armpits!*
  ]
]
```

## 026 — Types of reference

Category: Functional Grammar
Settings: color=none fontstyle=noto-serif leafstyle=bar polyline=on tidy=high vheight=1.5
Source: Halliday and Hasan 1976: 33

```
[Reference:
  [\[situational\]\
     exophora
  ]
  [\[textual\]\
     endophora
    [\[to<>preceding<>text\]\
     anaphora
    ]
    [\[to<>following<>text\]\
     cataphora
    ]
  ]
]
```

## 027 — Types of rejoinder

Category: Functional Grammar
Settings: color=none fontstyle=noto-serif leafstyle=bar polyline=on tidy=low vheight=3.0
Source: Halliday and Hasan 1976: 207

```
[REJOINDER\
 (any<>cohesive<>sequel<>by<>different<>speaker)
  [(following<>a<>question)\
    RESPONSE
    [(answering)\
     DIRECT\
     RESPONSE
    ]
    [(not<>answering)\
     INDIRECT<>RESPONSE
      [(attitude<>to<>answer)\
       COMMENTARY
      ]
      [(evading<>answer)\
       DISCLAIMER
      ]
      [(implying<>answer)\
       SUPPLEMENTARY\
       RESPONSE
      ]
    ]
  ]
  [(not<>following<>a<>question)\
   \[other<>rejoinders\]
    [(following<>a<>statement)
      [ASSENT]
      [CONTRADICTION]
    ]
    [(following<>a\
     statement<>or\
     command)\
     QUESTION\
     REJOINDER
    ]
    [(following<>\
     a<>command)
      [CONSENT]
      [REFUSAL]
    ]
  ]
]
```

## 028 — Basic tree with triangles

Category: General
Settings: fontstyle=noto-serif tidy=low vheight=1.0

```
[NP
  [NP a picture]
  [PP
    [P of]
    [NP ^cats]
  ]
]
```

## 029 — Animal ontology

Category: Formal Concept Analysis
Settings: color=none fontstyle=noto-sans-mono tidy=low

```
[##Human,<>Bonobo,<>Lion,<>Eagle,<>Sparrow,<>Ostrich\
 ---\
 <>
  [##Human\
   ---\
   talking,<>ape,<>mammal
     [##Bonobo\
      ---\
      ape,<>mammal+-1]
  ]
  [##Lion\
   ---\
   mammal,<>preying+-4+-6
     [<>\ <>\ <>
       [##<>\
        ---\
        mammal+-1+-2+-4
      ]
    ]
  ]
  [##Eagle\
   ---\
   preying,<>flying,<>bird
     [##<>\
      ---\
      preying+-5+-6
      [<>\ <>\ <>
        [##<>\
         ---\
         talking,<>ape,<>mammal,<>preying,<>flying,<>bird+-2+-3+-5
        ]
      ]
    ]
    [##Sparrow\
     ---\
     flying,<>bird
      [##Ostrich\
       ---\
       bird<>+-3
      ]
    ]
  ]
]
```

## 030 — Construction network

Category: Construction Grammar
Settings: color=none fontstyle=noto-serif vheight=3.0
Source: Goldberg 1995: 109

```
[##Subject\-Predicate<>Construction
  [##Intransitive+-1
    [<>
      [<>
          [##Intransitive<>Motion\
           ---\
           *The<>boy<>ran<>home.*+-1+-2]
      ]
    ]
  ]
  [##Transitive
   [##Caused\-Motion\
    ---\
    *Pat<>sneezed<>the<>napkin<>off<>the<>table.*+-2]
    [##Ditransitive\
     ---\
     *Pat<>threw<>Chris<>the<>ball.*
    ]
  ]
]
```

## 031 — Lambda calculus

Category: Formal Semantics
Settings: color=none fontstyle=noto-sans-mono tidy=low vheight=1.5

```
[chase(mouse)(cat)
  [<>λx.λy.chase(mouse)(y)<>
    [<>λxλy.chase(x)(y)<>]
    [<>mouse<>]
  ]
  [<>cat<>]
]
```

## 034 — Taxonomic Hierarchy of clauses

Category: Construction Grammar
Settings: color=none fontstyle=noto-serif vheight=2.5
Source: Croft and Cruse 2004: 264

```
[##Clause
  [##Sbj<>IntrVerb
    [##Sbj<>*sleep*]
    [##Sbj<>*run*]
  ]
  [##Sbj<>TrVerb<>Obj
    [##Sbj<>*kick*<>Obj
      [##Sbj<>*kick<>the<>bucket*]
      [##Sbj<>*kick<>the<>habit*]
    ]
    [##Sbj<>*kiss*<>Obj]
  ]
]
```

## 035 — Construction network

Category: Construction Grammar
Settings: color=none fontstyle=noto-serif hide_default_connectors=on tidy=symmetric vheight=3.0
Source: Goldberg 1995: 109

```
[##Caused\-Motion\
 ---\
 *Pat<>sneezed<>the<>napkin<>off<>the<>table*+-2+-4+-5
  [##Resultative\
   ---\
   *She<>kissed<>him<>unconsicous*+-1+-4
    [<>
      [##Intransitive<>Resultative\
      ---\
      *The<>jello<>went<>from<>liquid<>to<>solid*+-1+-3]
    ]
  ]
  [<>
    [##Intransitive<>Motion\
    ---\
    *The<>boy<>ran<>home*+-2+-3]
  ]
  [##Transfer\
  ---\
  *Sally<>threw<>a<>football<>to<>him*+-5]
]
```

## 036 — Schema network

Category: Cognitive Grammar
Settings: fontstyle=noto-serif hide_default_connectors=on tidy=symmetric

```
[##Schema+->0+->1
  [##Prototype+->0+-2]
  [##Extention+->1+->2]
]
```

## 037 — Action chain

Category: Cognitive Grammar
Settings: fontstyle=noto-serif hide_default_connectors=on tidy=symmetric vheight=1.0

```
[###John<>opened<>the<>door<>with<>the<>key\
    <>\
    {}->{}->{}->\
    <>\
    AGT<>\><>INST<>\><>PAT
]
```

## 038 — Relations between WordNet senses

Category: Natural Language Processing
Settings: color=none fontstyle=noto-sans-mono hide_default_connectors=on tidy=symmetric
Source: Jurafsky and Martin 2018

```
[##hypernym+-<1
  [##meronym+-<2
    [meronymy/part\-whole+-2+-3+-<4
      [##holonym+-<3]
    ]
  ]
  [superordinate+-1+-<7
    [###word+-4+-<6+-7+-8
      [subordinate+-5+-<8
        [##hyponym+-<5]
      ]
    ]
  ]
  [<>
    [##synonym+-<6]
  ]
]
```

## 040 — Sound feature geometry

Category: Phonology
Settings: color=none fontstyle=noto-sans-mono polyline=on tidy=low vheight=1.5
Source: Halle 1992

```
[root\
 \[cons\]\<>\[sonor\]\
 stricture\
 \[later\]\<>\[strid\]\<>\[contin\]
  [cavity\ Oral
    [articulator\ Labial
      terminal\
      features\
      \[round\]
    ]
    [articulator\ Coronal
      terminal\
      features\
      \[anter\]\
      \[distrib\]
    ]
    [articulator\ Dorsal
      terminal\
      features\
      \[back\]\
      \[high\]\
      \[low\]
    ]
  ]
  [cavity\ Nasal
    [articulator\ Soft<>Palate
      terminal\
      features\
      \[nasal\]
    ]
  ]
  [cavity\ Pharyngeal
    [articulator\ Radical
      terminal\
      features\
      \[ATR\]\
      \[RTR\]
    ]
    [articulator\ Glottal
      terminal\
      features\
      \[spread<>gl\]\
      \[constr<>gl\]\
      \[voiced\]
    ]
  ]
]
```

## 041 — Cognitive science linkages

Category: Miscellaneous
Settings: color=gray fontstyle=noto-serif hide_default_connectors=on hspacing=0.75 tidy=symmetric vheight=1.5
Source: Miller et al. 1978

```
[##Philosophy+-1+-2+-3+-4+-5
  [##Psychology+-1+-6+-7+-8+-9+-10
    [<>
      [##Computer<>Science+-2+-6+-7+-11+-12+-13]
    ]
  ]
  [<>
    [<>
      [<>
        [##Neuroscience+-3+-8+-11+-14+-15]
      ]  
    ]
  ]
  [##Linguistics+-4+-9+-12+-14+-16
    [<>
      [##Anthropology+-5+-10+-13+-15+-16]
    ]
  ]
]
```

## 042 — Merge

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif leafstyle=nothing tidy=low vheight=1.0

```
[γ
  γ
  [α
    [α]
    [β]
  ]
]
```

## 043 — Quick sort

Category: Computer Science
Settings: fontstyle=noto-sans tidy=low

```
[|20||2||14||9||15||16||11||19||10||**13**|
  [|2||9||12||11||**10**|+->0
    [|2||9|+->2
      [|2|]
      [|9|]
    ] 
    [|10|+-2+-3]
    [|12||11|+->3
      [|12|+->6]
      [|11|+->6]
    ] 
  ]
 [|13|+-0+-1]
 [|20||14||15||19||**16**|+->1
    [|14||15|+->4
      [|14|]
      [|15|]
    ]  
    [|16|+-4+-5]
    [|20||19|+->5
      [|20|+->7]
      [|19|+->7]
    ]  
  ]  
]
```

## 045 — Prototypical organization of English nominals

Category: Cognitive Grammar
Settings: fontstyle=noto-serif
Source: Langacker 1991: 147

```
[##Nominal
  [##Grounding\
     Predication+-1]
  [##Quantified\
     Instance+->1
    [##Absolute\
       Quantifier+-2]
    [###Higher\-Order\
        Instantiated\
        Type+->2
      [###Higher\-Order\
          Instantiated\
          Type+->3
        [##Modifier+-4]
        [###Head<>Noun\
            ---\
            Basic\
            Instantiated\
            Type+->4+->5
            [##Basic<>Type<>Specification\
               ---\
               Underived<>Stem\
               Plural<>Stem\
               Derived<>Stem\
               Compound<>Stem+-5
            ]
        ]
      ] 
      [###Modifier+-3]
    ]
  ]
]
```

## 048 — Conjunctive adjuncts [elaboration]

Category: Functional Grammar
Settings: fontstyle=noto-serif polyline=on tidy=low vheight=1.5
Source: Halliday 2014: 612-614

```
[conjunctive<>adjuncts
  [elaboration
    [apposition
      [expository
        in<>other<>words\
        that<>is<>(to<>say)\
        I<>mean<>(to<>say)\
        to<>put<>it<>another<>way
      ]
      [exemplifying
        for<>example\
        for<>insntance\
        thus\
        to<>illustrate
      ]
    ]
    [clarification
      [corrective
        or<>rather\
        at<>least\
        to<>be<>more<>precise
      ]
      [distractive
        by<>the<>way\
        incidentally
      ]
      [dismissive
        in<>any<>case\
        anyway\
        leaving<>that<>aside
      ]
      [particularizing
        in<>particular\
        more<>especially
      ]
      [resumptive
        as<>I<>wasy<>saying\
        to<>resume\
        to<>get<>back<>to<>the<>point
      ]
      [summative
        in<>short\
        to<>sum<>up\
        in<>conclusion\
        briefly
      ]
      [verifactive
        actually\
        as<>a<>matter<>of<>fact\
        in<>fact\
        indeed
      ]
    ]
  ]
]
```

## 049 — Conjunctive adjuncts [extension]

Category: Functional Grammar
Settings: fontstyle=noto-serif polyline=on tidy=low vheight=1.5
Source: Halliday 2014: 612-614

```
[conjunctive<>adjuncts
  [extension
    [addition
      [positive
        and\
        also\
        moreover\
        in<>addition
      ]
      [negative
        nor
      ]
      [adversative
        but\
        yet\
        on<>the<>other<>hand\
        however
      ]
    ]
    [variation
      [replacive
        on<>the<>contrary\
        instead
      ]
      [subtractive
        alternatively
      ]
      [alternative
        alternatively
      ]
    ]
  ]
]
```

## 050 — Conjunctive adjuncts [enhancement (1)]

Category: Functional Grammar
Settings: fontstyle=noto-serif polyline=on tidy=low vheight=1.5
Source: Halliday 2014: 612-614

```
[conjunctive<>adjuncts
  [enhancement<>(1)
    [temporal
      [simple
        [following
          then\
          next\
          afterwords\
          first<>...<>then
        ]
        [simultaneous
          just<>then\
          at<>the<>same<>time
        ]
        [preceding
          before<>that\
          hitherto\
          previously
        ]
        [conclusive
          in<>the<>end\
          finally
        ]
      ]
      [complex
        [immediate
          at<>once\
          thereupon\
          straightaway
        ]
        [interrupted
          soon\
          after<>a<>while
        ]
        [repetitive
          next<>time\
          on<>another<>occasion
        ]
        [specific
          next<>day\
          an<>hour<>later\
          that<>morning
        ]
        [durative
          meanwhile\
          all<>that<>time
        ]
        [terminal
          until<>then\
          up<>to<>that<>point
        ]
        [punctiliar
          at<>this<>point
        ]
      ]
      [simple<>internal
        [following
          next\
          secondly\
          my<>next<>pooint<>is\
          first<>...<>next
        ]
        [simultaneous
          at<>this<>point\
          here\
          now
        ]
        [preceding
          hitherto\
          up<>to<>now
        ]
        [conclusive
          lastly\
          last<>of<>all\
          finally
        ]
      ]
    ]
  ]
]
```

## 051 — Conjunctive adjuncts [enhancement (2)]

Category: Functional Grammar
Settings: fontstyle=noto-serif polyline=on tidy=low vheight=1.5
Source: Halliday 2014: 612-614

```
[conjunctive<>adjuncts
  [enhancement<>(2)
    [manner
      [comparison
        [positive
          likewise\
          similarly
        ]
        [negative
          in<>a<>different<>way
        ]
      ]
      [means
        thus\
        thereby\
        by<>such<>means
      ]
    ]
    [causal\-conditional
      [general
        so\
        then\
        therefore\
        consequently\
        hense\
        because<>of<>that\
        for
      ]
      [specific
        [result
          in<>consequence\
          as<>a<>result
        ]
        [reason
          on<>account<>of<>this\
          for<>that<>reason
        ]
        [purpose
          for<>that<>purpose\
          with<>this<>in<>view
        ]
        [conditional:\
         positive
          then\
          in<>that<>case\
          in<>that<>event\
          under<>the<>circumstances
        ]
        [conditional:\
         negative
          otherwise\
          if<>not
        ]
        [concessive
          yet\
          still\
          though\
          despite<>this\
          however\
          even<>so\
          all<>the<>same\
          nevertheless
        ]
      ]
    ]
    [matter
      [positive
        here\
        there\
        as<>to<>that\
        in<>that<>respect
      ]
      [negative
        in<>other<>respects\
        elsewhere
      ]
    ]
  ]
]
```

## 052 — Major clause constructions of English

Category: Construction Grammar
Settings: color=none fontstyle=noto-serif polyline=on vheight=3.0
Source: Hoffmann 2022: 220

```
[ Major<>clause<>construction
  [Declarative<>clause<>cxn\
   ---\
   *He<>was<>tired.*\
   *He<>made<>mistakes.*
  ]
  [Interrogative<>cxn\
   [Yes/No interrogative<>cxn\
    ---\
    *Was<>he<>tired?*\
    *Did<>he<>make<>mistakes?*
   ]
   [WH\-interrogative<>cxn
    [WH\-subject<>interrogative<>cxn\
     ---\
     *Who<>was<>tired?*
    ]
    [WH\-nonsubject<>interrogative<>cxn\
     ---\
     *What<>was<>he?*\
     *What<>did<>he<>make?*
    ]
   ]
  ]
  [WH\-exclamative<>cxn\
   ---\
   *How<>tired<>he<>was!*\
   *What<>mistakes<>he<>made!*
  ]
  Imperative<>cxn
  [Relative<>clause<>cxn\
   [WH\-subject<>relative<>clause<>cxn\
    ---\
    The<>emails,<>which<>arrived<>overnight<>...
   ]
   [WH\-nonsubject<>relative<>clause<>cxn\
    ---\
    A<>pilot<>shouldn't<>be<>tired,<>which<>Ben<>was.\
    The<>mistalkes<>that<>he<>made<>...
   ]
  ]
]
```

## 053 — Escaping square brackets

Category: Miscellaneous
Settings: fontstyle=noto-serif tidy=low

```
[expr
  [expr
    [expr
      [id x]
      [suffix \[2\]]
    ]
    [suffix \[3\]]
  ]
  [suffix \[4\]]
]
```

## 054 — Per-node coloring (named colors)

Category: Miscellaneous
Settings: fontstyle=noto-sans tidy=low vheight=1.2

```
[S
  [@red:NP the dog]
  [@blue:VP
    [@green:V runs]
    [@orange:Adv quickly]
  ]
]
```

## 055 — Per-leaf coloring (hex colors)

Category: Miscellaneous
Settings: fontstyle=noto-sans tidy=low vheight=1.2

```
[S
  [NP
    [Det @#E63946:the]
    [N @#457B9D:cat]
  ]
  [VP
    [V @#2A9D8F:sleeps]
  ]
]
```

## 056 — Per-node coloring with enclosure and triangle

Category: Miscellaneous
Settings: fontstyle=noto-sans tidy=low

```
[S
  [#@red:NP the quick brown fox]
  [#@green:VP
    [V jumps]
    [PP
      [P over]
      [^@purple:NP the lazy dog]
    ]
  ]
]
```

## 057 — Subscript and superscript

Category: Miscellaneous
Settings: fontstyle=noto-serif tidy=low vheight=1.5

```
[TP
  [DP_i_ John]
  [T'
    [T__0__ pres]
    [VP
      [V believes]
      [TP
        [DP_i_ himself]
        [T'
          [T__0__ to]
          [VP
            [V be]
            [AP smart]
          ]
        ]
      ]
    ]
  ]
]
```

## 058 — Types of meaning (left-to-right)

Category: Pragmatics
Settings: color=none direction=ltr fontstyle=noto-serif leafstyle=bar polyline=on tidy=low vheight=1.5
Source: Zufferey, Moeschler, and Reboul 2014

```
[Types<>of<>meaning
  [conventional
    [semantic
      [entailment]
      [presupposition]
    ]
    [pragmatic
      [conventional\
       implicature]
    ]
  ]
  [non\-conventional
    [explicit
      [explicature]
    ]
    [implicit
      [conventional
        [generalized\
         implicature]
        [particularized\
         implicature]
      ]
      [non\-\
       conventional
        [pragmatic\
         presupposition]
      ]
    ]
  ]
]
```

## 059 — Major clause constructions of English (left-to-right)

Category: Construction Grammar
Settings: color=none direction=ltr fontstyle=noto-serif leafstyle=bar polyline=on tidy=low vheight=1.5
Source: Hoffmann 2022: 220

```
[Major<>clause<>construction
  [Declarative<>clause<>cxn
    [*He<>was<>tired.*\
     *He<>made<>mistakes.*]
  ]
  [Interrogative<>cxn
    [Yes/No
      [interrogative<>cxn
        [*Was<>he<>tired?*\
         *Did<>he<>make<>mistakes?*]
      ]
    ]
    [WH\-interrogative<>cxn
      [WH\-subject<>interrogative<>cxn
        [*Who<>was<>tired?*]
      ]
      [WH\-nonsubject<>interrogative<>cxn
        [*What<>was<>he?*\
         *What<>did<>he<>make?*]
      ]
    ]
  ]
  [WH\-exclamative<>cxn
    [*How<>tired<>he<>was!*\
     *What<>mistakes<>he<>made!*]
  ]
  [Imperative<>cxn]
  [Relative<>clause<>cxn
    [WH\-subject<>relative<>clause<>cxn
      [*The<>emails,<>which<>arrived<>overnight<>...*]
    ]
    [WH\-nonsubject<>relative<>clause<>cxn
      [*A<>pilot<>shouldn't<>be<>tired,<>which<>Ben<>was.*\
       *The<>mistakes<>that<>he<>made<>...*]
    ]
  ]
]
```

## 060 — Conjunctive adjuncts: elaboration (left-to-right)

Category: Functional Grammar
Settings: direction=ltr fontstyle=noto-sans leafstyle=bar polyline=on tidy=low vheight=1.0
Source: Halliday 2014: 612-614

```
[conjunctive<>adjuncts
  [elaboration
    [apposition
      [expository
        [in<>other<>words\
         that<>is<>(to<>say)\
         I<>mean<>(to<>say)\
         to<>put<>it<>another<>way]
      ]
      [exemplifying
        [for<>example\
         for<>instanace\
         thus\
         to<>illustrate]
      ]
    ]
    [clarification
      [corrective
        [or<>rather\
         at<>least\
         to<>be<>more<>precise]
      ]
      [distractive
        [by<>the<>way\
         incidentally]
      ]
      [dismissive
        [in<>any<>case\
         anyway\
         leaving<>that<>aside]
      ]
      [particularizing
        [in<>particular\
         more<>especially]
      ]
      [resumptive
        [as<>I<>wasy<>saying\
         to<>resume\
         to<>get<>back<>to<>the<>point]
      ]
      [summative
        [in<>short\
         to<>sum<>up\
         in<>conclusion\
         briefly]
      ]
      [verifactive
        [actually\
         as<>a<>matter<>of<>fact\
         in<>fact\
         indeed]
      ]
    ]
  ]
]
```

## 061 — Conjunctive adjuncts: enhancement 1 (left-to-right)

Category: Functional Grammar
Settings: direction=ltr fontstyle=noto-sans leafstyle=bar polyline=on tidy=low vheight=1.0
Source: Halliday 2014: 612-614

```
[conjunctive<>adjuncts
  [enhancement<>(1)
    [temporal
      [simple
        [following
          [then\
           next\
           afterwards\
           first<>...<>then]
        ]
        [simultaneous
          [just<>then\
           at<>the<>same<>time]
        ]
        [preceding
          [before<>that\
           hitherto\
           previously]
        ]
        [conclusive
          [in<>the<>end\
           finally]
        ]
      ]
      [complex
        [immediate
          [at<>once\
           thereupon\
           straightaway]
        ]
        [interrupted
          [soon\
           after<>a<>while]
        ]
        [repetitive
          [next<>time\
           on<>another<>occasion]
        ]
        [specific
          [next<>day\
           an<>hour<>later\
           that<>morning]
        ]
        [durative
          [meanwhile\
           all<>that<>time]
        ]
        [terminal
          [until<>then\
           up<>to<>that<>point]
        ]
        [punctiliar
          [at<>this<>point]
        ]
      ]
      [simple<>internal
        [following
          [next\
           secondly\
           my<>next<>pooitn<>is\
           first<>...<>next]
        ]
        [simultaneous
          [at<>this<>point\
           here\
           now]
        ]
        [preceding
          [hitherto\
           up<>to<>now]
        ]
        [conclusive
          [lastly\
           last<>of<>all\
           finally]
        ]
      ]
    ]
  ]
]
```

## 062 — Conjunctive adjuncts: enhancement 2 (left-to-right)

Category: Functional Grammar
Settings: direction=ltr fontstyle=noto-sans leafstyle=bar polyline=on tidy=low vheight=1.0
Source: Halliday 2014: 612-614

```
[conjunctive<>adjuncts
  [enhancement<>(2)
    [manner
      [comparison
        [positive
          [likewise\
           similarly]
        ]
        [negative
          [in<>a<>different<>way]
        ]
      ]
      [means
        [thus\
         thereby\
         by<>such<>means]
      ]
    ]
    [causal\-conditional
      [general
        [so\
         then\
         therefore\
         consequently\
         hence\
         because<>of<>that\
         for]
      ]
      [specific
        [result
          [in<>consequence\
           as<>a<>result]
        ]
        [reason
          [on<>account<>of<>this\
           for<>that<>reason]
        ]
        [purpose
          [for<>that<>purpose\
           with<>this<>in<>view]
        ]
        [conditional:\
         positive
          [then\
           in<>that<>case\
           in<>that<>event\
           under<>the<>circumstances]
        ]
        [conditional:\
         negative
          [otherwise\
           if<>not]
        ]
        [concessive
          [yet\
           still\
           though\
           despite<>this\
           however\
           even<>so\
           all<>the<>same\
           nevertheless]
        ]
      ]
    ]
    [matter
      [positive
        [here\
         there\
         as<>to<>that\
         in<>that<>respect]
      ]
      [negative
        [in<>other<>respects\
         elsewhere]
      ]
    ]
  ]
]
```

## 063 — vP-shell with movement paths (left-to-right)

Category: Generative Grammar
Settings: direction=ltr fontstyle=noto-serif leafstyle=nothing tidy=low vheight=1.5
Source: Radford 2004

```
[CP
  [C
   ø]
  [TP
    [PRN
    **They**+>2
    ]
    [T'
      [T
       Will
      ]
      [vP
        [PRN
         ~**they**~+2
        ] 
        [v'
          [v
           ø<>\+<>*get*+>1
          ]
          [VP
            [DP
             the<>teacher]
            [V'
              [V
               ~*get*~+1
              ]
              [QP
               a<>present
              ]
            ]
          ]
        ]  
      ]
    ]
  ]
]
```

## 064 — Region shade for a c-command domain

Category: Generative Grammar
Settings: fontstyle=noto-serif tidy=low

```
[TP
  [DP everyone]
  [%@lightblue:T'
    [T will]
    [VP
      [V praise]
      [DP his_i_ friend]
    ]
  ]
]
```

## 065 — Nested region shades (overlapping domains)

Category: Generative Grammar
Settings: color=none fontstyle=noto-serif

```
[%S
  [DP everyone]
  [%VP
    [V loves]
    [%NP Mary]
  ]
]
```

## 066 — Parallel example — English (Latin script)

Category: Multilingual
Settings: fontstyle=noto-sans tidy=low vheight=1.2
Source: UD-PUD w01071036 (Zeman et al. 2017); constituency derived from the dependencies

```
[S
  [NP
    [PRON Its]
    [NOUN importance]
  ]
  [VP
    [VERB resides]
    [PP
      [ADP in]
      [NP
        [NUM two]
        [NOUN facts]
      ]
    ]
  ]
]
```

## 067 — Parallel example — Arabic (right-to-left tree via the mirror option)

Category: Multilingual
Settings: fontstyle=noto-sans mirror=on tidy=low vheight=1.2
Source: UD-PUD w01071036 (Zeman et al. 2017); constituency derived from the dependencies

```
[S
  [VP
    [VERB تكمن]
    [NP
      [NOUN أهميت]
      [PRON ه]
    ]
  ]
  [PP
    [ADP في]
    [NOUN حقيقتين]
  ]
]
```

## 068 — Parallel example — Hindi (Devanagari: reordering and conjuncts)

Category: Multilingual
Settings: fontstyle=noto-sans tidy=low vheight=1.2
Source: UD-PUD w01071036 (Zeman et al. 2017); constituency derived from the dependencies

```
[AP
  [NP
    [PRON इसका]
    [NOUN महत्व]
  ]
  [AP
    [PP
      [NP
        [NUM दो]
        [NOUN तथ्यों]
      ]
      [ADP में]
    ]
    [AP
      [ADJ निहित]
      [AUX है]
    ]
  ]
]
```

## 069 — Parallel example — Thai (stacked marks, no word spacing)

Category: Multilingual
Settings: fontstyle=noto-sans tidy=low vheight=1.2
Source: UD-PUD w01071036 (Zeman et al. 2017); constituency derived from the dependencies

```
[S
  [ADJ ความสำคัญ]
  [VP
    [VERB อยู่]
    [NP
      [NP
        [PP
          [ADP ใน]
          [NOUN ข้อ]
        ]
        [ADJ เท็จจริง]
      ]
      [NumP
        [NUM สอง]
        [NOUN ประการ]
      ]
    ]
  ]
]
```

## 070 — Parallel example — Japanese (kanji and kana)

Category: Multilingual
Settings: fontstyle=noto-sans tidy=low vheight=1.2
Source: UD-PUD w01071036 (Zeman et al. 2017); constituency derived from the dependencies

```
[S
  [NP
    [PP
      [NP
        [NUM 2]
        [NOUN つ]
      ]
      [ADP の]
    ]
    [PP
      [NOUN 事実]
      [ADP が]
    ]
  ]
  [VP
    [AP
      [ADJ 重要]
      [AUX に]
    ]
    [VP
      [VERB なり]
      [AUX ます]
    ]
  ]
]
```

## 071 — Parallel example — Korean (Hangul)

Category: Multilingual
Settings: fontstyle=noto-sans tidy=low vheight=1.2
Source: UD-PUD w01071036 (Zeman et al. 2017); constituency derived from the dependencies

```
[S
  [NP
    [DET 그]
    [NOUN 중요성이]
  ]
  [VP
    [VP
      [NP
        [NP
          [DET 두]
          [NOUN 가지]
        ]
        [NOUN 사실에]
      ]
      [VERB 숨어]
    ]
    [AUX 있다]
  ]
]
```

## 072 — Parallel example — Russian (Cyrillic)

Category: Multilingual
Settings: fontstyle=noto-sans tidy=low vheight=1.2
Source: UD-PUD w01071036 (Zeman et al. 2017); constituency derived from the dependencies

```
[S
  [NOUN Важность]
  [VP
    [VERB заключается]
    [PP
      [ADP в]
      [NP
        [NUM двух]
        [NOUN фактах]
      ]
    ]
  ]
]
```

## 073 — Parallel example — Turkish (Latin with diacritics)

Category: Multilingual
Settings: fontstyle=noto-sans tidy=low vheight=1.2
Source: UD-PUD w01071036 (Zeman et al. 2017); constituency derived from the dependencies

```
[AP
  [AP
    [NP
      [NP
        [NUM İki]
        [NOUN olgu]
      ]
      [NOUN bakımından]
    ]
    [ADJ önemli]
  ]
  [AUX dir]
]
```

## 074 — Parallel example — Chinese (logographic han characters)

Category: Multilingual
Settings: fontstyle=noto-sans tidy=low vheight=1.2
Source: UD-PUD w01071036 (Zeman et al. 2017); constituency derived from the dependencies

```
[S
  [AP
    [PRON 其]
    [ADJ 重要性]
  ]
  [VP
    [PP
      [ADP 在]
      [PP
        [NP
          [NP
            [NUM 兩]
            [NOUN 個]
          ]
          [NOUN 事實]
        ]
        [ADP 中]
      ]
    ]
    [VP
      [VERB 反應]
      [VERB 出來]
    ]
  ]
]
```

## 075 — Morphological derivation of <i>internationalization</i>

Category: Morphology
Settings: fontstyle=noto-serif tidy=high vheight=1.2

```
[N
  [V
    [A
      [Af inter\-]
      [A
        [N nation]
        [Af \-al]
      ]
    ]
    [Af \-ize]
  ]
  [Af \-ation]
]
```

## 076 — Nested feature structure

Category: Head-Driven Phrase Structure Grammar
Settings: color=none fontstyle=noto-serif hyphen=literal leafstyle=bar linewidth=0.5 tidy=low vheight=1.0
Source: cf. Sag, Wasow and Bender 2003

```
[#*word*\
  PHON\t⟨<>*relies*<>⟩\
  SYNSEM\t#(LOC\t#(CAT\t#(HEAD\t#(*verb*\
    VFORM\t*fin*#)\
    VAL\t#(SPR\t⟨<>|1|<>⟩\
    COMPS\t⟨<>|2|<>⟩#)#)\
    CONT\t#(*rely-rel*\
    RELIER\t|1|\
    RELIED-ON\t|2|#)#)#)
]
```

## 077 — Annotated c-structure

Category: Lexical-Functional Grammar
Settings: color=none fontstyle=noto-serif tidy=low vheight=1.5
Source: Bresnan 2001

```
[S
  [NP\
   (↑SUBJ)\=↓
    David
  ]
  [VP\
   ↑\=↓
    [V\
     ↑\=↓
      handed
    ]
    [NP\
     (↑OBJ)\=↓
      Chris
    ]
    [NP\
     (↑OBJ_θ_)\=↓
      a toy
    ]
  ]
]
```

## 078 — F-structure

Category: Lexical-Functional Grammar
Settings: color=none fontstyle=noto-serif leafstyle=bar linewidth=0.5 tidy=low vheight=1.0
Source: Bresnan 2001

```
[#PRED\t‘hand⟨SUBJ,<>OBJ,<>OBJ_θ_⟩’\
  TENSE\t*past*\
  SUBJ\t#(PRED\t‘David’#)\
  OBJ\t#(PRED\t‘Chris’#)\
  OBJ_θ_\t#(SPEC\t*a*\
  PRED\t‘toy’#)
]
```

## 079 — Discourse representation structure

Category: Formal Semantics
Settings: color=none fontstyle=noto-serif leafstyle=bar tidy=low vheight=1.0
Source: Kamp and Reyle 1993

```
[##x<>y\
---\
farmer(x)\
donkey(y)\
own(x,<>y)
]
```

## 080 — Terminals levelled with pass-through joints

Category: General
Settings: fontstyle=noto-serif tidy=low vheight=1.0

```
[S
  [NP [D [<> [<> the]]] [N [<> [<> cat]]]]
  [VP
    [V [<> [<> sat]]]
    [PP [P [<> on]] [NP [D the] [N mat]]]]]
```

## 081 — CCG derivation: right node raising

Category: Combinatory Categorial Grammar
Settings: color=none derivation=on direction=btt fontstyle=noto-serif hspacing=2.0 leafstyle=nothing tidy=low vheight=0.5
Source: Steedman 2000

```
[S\t>
  [S/NP\t<Φ>
    [S/NP\t>B
      [S/(S\\NP)\t>T
        [NP Mary]]
      [(S\\NP)/NP likes]]
    [conj and]
    [S/NP\t>B
      [S/(S\\NP)\t>T
        [NP Bill]]
      [(S\\NP)/NP hates]]]
  [NP London]]
```
