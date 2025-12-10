// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

//#assert(sys.version.at(1) >= 11 or sys.version.at(0) > 0, message: "This template requires Typst Version 0.11.0 or higher. The version of Quarto you are using uses Typst version is " + str(sys.version.at(0)) + "." + str(sys.version.at(1)) + "." + str(sys.version.at(2)) + ". You will need to upgrade to Quarto 1.5 or higher to use apaquarto-typst.")

// counts how many appendixes there are
#let appendixcounter = counter("appendix")
// make latex logo
// https://github.com/typst/typst/discussions/1732#discussioncomment-11286036
#let TeX = {
  set text(font: "New Computer Modern",)
  let t = "T"
  let e = text(baseline: 0.22em, "E")
  let x = "X"
  box(t + h(-0.14em) + e + h(-0.14em) + x)
}

#let LaTeX = {
  set text(font: "New Computer Modern")
  let l = "L"
  let a = text(baseline: -0.35em, size: 0.66em, "A")
  box(l + h(-0.32em) + a + h(-0.13em) + TeX)
}

#let firstlineindent=0.5in

// documentmode: man
#let man(
  title: none,
  runninghead: none,
  margin: (x: 1in, y: 1in),
  paper: "us-letter",
  font: ("Times", "Times New Roman"),
  fontsize: 12pt,
  leading: 18pt,
  spacing: 18pt,
  firstlineindent: 0.5in,
  toc: false,
  lang: "en",
  cols: 1,
  numbersections: false,
  numberdepth: 3,
  first-page: 1,
  suppresstitlepage: false,
  doc,
) = {

  if suppresstitlepage {counter(page).update(first-page)}

  set page(
    margin: margin,
    paper: paper,
    header-ascent: 50%,
    header: grid(
      columns: (9fr, 1fr),
      align(left)[#upper[#runninghead]],
      align(right)[#context counter(page).display()]
    )
  )
  

  

 

  set table(    
    stroke: (x, y) => (
        top: if y <= 1 { 0.5pt } else { 0pt },
        bottom: .5pt,
      )
  )

  set par(
    justify: false, 
    leading: leading,
    first-line-indent: firstlineindent
  )

  // Also "leading" space between paragraphs
  set block(spacing: spacing, above: spacing, below: spacing)

  set text(
    font: font,
    size: fontsize,
    lang: lang
  )
  
  show link: set text(blue)
  show "al.'s": "al.\u{2019}s"

  show quote: set pad(x: 0.5in)
  show quote: set par(leading: leading)
  show quote: set block(spacing: spacing, above: spacing, below: spacing)
  // show LaTeX
  show "TeX": TeX
  show "LaTeX": LaTeX

  // format figure captions
  show figure.where(kind: "quarto-float-fig"): it => block(width: 100%, breakable: false)[
    #if int(appendixcounter.display().at(0)) > 0 [
      #heading(level: 2, outlined: false)[#it.supplement #appendixcounter.display("A")#it.counter.display()]
    ] else [
      #heading(level: 2, outlined: false)[#it.supplement #it.counter.display()]
    ]
    #align(left)[#par[#emph[#it.caption.body]]]
    #align(center)[#it.body]
  ]
  
  // format table captions
  show figure.where(kind: "quarto-float-tbl"): it => block(width: 100%, breakable: false)[#align(left)[
  
    #if int(appendixcounter.display().at(0)) > 0 [
      #heading(level: 2, outlined: false, numbering: none)[#it.supplement #appendixcounter.display("A")#it.counter.display()]
    ] else [
      #heading(level: 2, outlined: false, numbering: none)[#it.supplement #it.counter.display()]
    ]
    #par[#emph[#it.caption.body]]
    #block[#it.body]
  ]]
  
    set heading(numbering: "1.1")
    
    show heading: set text(size: fontsize)


 // Redefine headings up to level 5 
  show heading.where(
    level: 1
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(center)
    #if(numbersections and it.outlined and numberdepth > 0 and counter(heading).get().at(0) > 0) [#counter(heading).display()] #it.body
  ]
  
  show heading.where(
    level: 2
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(left)
    #if(numbersections and it.outlined and numberdepth > 1 and counter(heading).get().at(0) > 0) [#counter(heading).display()] #it.body
  ]
  
  show heading.where(
    level: 3
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(left)
    #set text(style: "italic")
    #if(numbersections and it.outlined and numberdepth > 2 and counter(heading).get().at(0) > 0) [#counter(heading).display()] #it.body
  ]

  show heading.where(
    level: 4
  ): it => text(
    weight: "bold",
    it.body
  )

  show heading.where(
    level: 5
  ): it => text(
    weight: "bold",
    style: "italic",
    it.body
  )
  
  

  if cols == 1 {
    doc
  } else {
    columns(cols, gutter: 4%, doc)
  }
  



}

#import "@preview/fontawesome:0.5.0": *

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: document => man(
  runninghead: "BETA REGRESSION TUTORIAL",
  lang: "en",
  numberdepth: 3,
  document,
)

\
\
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
The Frequentist Way: A Tutorial For Using Beta Regression in Pychological Research
]
)
]
#set align(center)
#block[
\
Jason Geller#super[1];, Robert Kubinec#super[2];, and Matti Vuorre#super[3]

#super[1];Department of Psychology and Neuroscience, Boston College

#super[2];University of South Carolina

#super[3];Tilburg University

]
#set align(left)
\
\
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Author Note
]
)
]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Jason Geller #box(image("_extensions/wjschne/apaquarto/ORCID-iD_icon-vector.svg", width: 4.23mm)) #link("https://orcid.org/0000-0002-7459-4505")

Correspondence concerning this article should be addressed to Jason Geller, Department of Psychology and Neuroscience, Boston College, McGuinn 300, Chestnut Hill, MA 2467, USA, Email: #link("mailto:drjasongeller@gmail.com")[drjasongeller\@gmail.com]

#pagebreak()

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Abstract
]
)
]
#block[
Rates, percentages, and proportional data are widespread in psychology and social sciences. These data are usually analyzed with methods falling under the general linear model, which are not ideal for this type of data. A better alternative is the beta regession model which is based on the beta distribution. A beta regression can be used to model continuous outcomes that are non-normal,non-linear, heteroscedastic, and bounded between an upper and lower interval, such as proportions and percentiles. Thus, the beta regression model is well-suited to examine outcomes in psycholgical research expressed as proportions, percentages, or ratios. The overall purpose of this tutorial is to give researchers a hands-on demonstration of how to use beta regression using a real example from the psychological literature. First, we introduce the beta distribution and the beta regression model highlighting crucial components and assumptions. Second, we highlight how to conduct a beta regression in R using an example dataset from the learning and memory literature. Some extensions of the beta model are then discussed (e.g., zero-inflated, zero- one-inflated, and ordered beta). We present accompanying R code throughout. All code to reproduce this paper can be found on Github: link forthcoming

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#emph[Keywords];: beta regression, tutorial, psychology, learning and memory

#pagebreak()

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
The Frequentist Way: A Tutorial For Using Beta Regression in Pychological Research
]
)
]
#block[
#callout(
body: 
[
This document provides a practical overview of how to run beta regression models using a frequentist approach. It is intended as a companion to our article, #emph["A Beta Way: A Tutorial for Using Beta Regression in Psychological Research."] For additional theoretical background, methodological details, and extended examples, readers should consult the full article. The present guide focuses specifically on the R packages and workflows available for fitting frequentist beta regression models.

]
, 
title: 
[
Note
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
, 
body_background_color: 
white
)
]
== Data and Methods
<data-and-methods>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The principles of beta regression are best understood in the context of a real data set. The example we are gonna use comes from the learning and memory literature. A whole host of literature has shown extrinsic cues like fluency (i.e., how easy something is to process) can influence metamemory (i.e., how well we think we will remember something). As an interesting example, a line of research has focused on instructor fluency and how that influences both metamemory and actual learning. When an instructor uses lots of non-verbal gestures, has variable voice dynamics/intonation, is mobile about the space, and includes appropriate pauses when delivering content, participants perceive them as more fluent, but it does not influence actual memory performance, or what we learn from them (#link(<ref-carpenter2013>)[#strong[carpenter2013?];];; #link(<ref-toftness2017>)[#strong[toftness2017?];];; #link(<ref-witherby2022>)[#strong[witherby2022?];];). While fluency of instructor has not been found to impact actual memory across several studies, (#link(<ref-wilford2020>)[#strong[wilford2020?];];) found that it can. In several experiments, (#link(<ref-wilford2020>)[#strong[wilford2020?];];) showed that when participants watched multiple videos of a fluent vs.~a disfluent instructor (here two videos as opposed to one), they remembered more information on a final test. Given the interesting, and contradictory results, we chose this paper to highlight. In the current tutorial we are going to re-analyze the final recall data from Wilford et al.~(2021; Experiment 1a). In the spirit of open science, the authors made their data available here:#link("https://osf.io/6tyn4/");.

Accuracy data is widely used in psychology and is well suited for Beta regression. Despite this, it is common to treat accuracy data as continuous and unbounded, and analyze the resulting proportions using methods that fall under the general linear model. Below we will reproduce the analysis conducted by (#link(<ref-wilford2020>)[#strong[wilford2020?];];) (Experiment 1a) and then re-analyze it using Beta regression. We hope to show how Beta regression and its extensions can be a more powerful tool in making inferences about your data.

In (#link(<ref-wilford2020>)[#strong[wilford2020?];];) (Expt 1a), they presented participants with two short videos highlighting two different concepts: (1) genetics of calico cats and (2) an explanation as to why skin wrinkles. Participants viewed either disfluent or fluent versions of these videos.#footnote[See an example of the fluent video here: #link("https://osf.io/hwzuk");. See an example of the disfluent video here: #link("https://osf.io/ra7be");.] For each video, metamemory was assessed using JOLs. JOLs require participants to rate an item on scale between 0-100 with 0 representing the item will not be remembered and a 100 representing they will definitely remember the item. In addition, other questions about the instructor were assessed and how much they learned. After a distractor task, a final free recall test was given were participants had to recall as much information about the video as they could in 3 minutes. Participants could score up to 10 points for each video. Here we will only being looking at the final recall data, but you could also analyze the JOL data with a beta regression.

== Reanalysis of Wilford et al.~Experiment 1a
<reanalysis-of-wilford-et-al.-experiment-1a>
#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Load packages and data.
]
)
]
As a first step, we will load the necessary packages along with the data we will be using. While we load all the necessary packages here, we also highlight when packages are needed as code chunks are run.

#block[
```r
# packages needed
library(tidyverse) # tidy functions/data wrangling/viz
library(glmmTMB) # zero inflated beta
library(betareg)
library(easystats)
library(gghalves)
library(scales) # percentage
library(tinytable) # tables
library(marginaleffects) # marginal effects

options(scipen = 999) # get rid of scienitifc notation
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We will read in the data from GitHub:

#block[
]
== Beta regression approach
<beta-regression-approach>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Using a traditional approach, we observed instructor fluency impacts actual learning. Keep in mind the traditional approach assumes normality of residuals and homoscadacity or constant variance. These assumptions are tricky to maintain when the continuous response approaches either the upper or lower boundary of the scale. Does the model `ols_model_new` meet those assumptions? Using `easystats` (#link(<ref-easystats>)[#strong[easystats?];];) and the `check_model` function, we can easily assess this. In #strong[?\@fig-ols-assump] , we see there definetly some issues with our model. Specifically, there appears to be violations of normality and constant variance (heteroscadacity).

One solution would be to run a beta regression model. Below we fit a beta regression using the `glmmTMB`package (#link(<ref-glmmTMB-4>)[#strong[glmmTMB-4?];];). This a popular package for running maximum likelihood (MLE) beta regressions with and without varying intercepts/random effects. Other packages that can be used to run beta regression include `betareg` (#link(<ref-betareg>)[#strong[betareg?];];) and also `gamlss` (#link(<ref-gamlss>)[#strong[gamlss?];];). In `glmmTMB` we fit a beta regression by using a formula similar to the ols model we fit above. However, we must specify the `family` argument as `beta_family(link = "logit")` to fit a vanilla beta regression.

#block[
```r
# load glmmTMB package
library(glmmTMB)
```

]
#block[
```r
beta_model <- glmmTMB(
  Accuracy ~ Fluency,
  disp = ~1,
  data = fluency_data,
  family = beta_family(link = "logit")
) # fits a constant for mu and dispersion
```

#block[
```
Error in eval(family$initialize): y values must be 0 < y < 1
```

]
]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
When you run the above model, an error will appear: `Error in eval(family$initialize) : y values must be 0 < y < 1`. Do not worry! This is by design. If your remember, the beta distribution can only model responses in the interval \[0-1\], but not responses that are exactly 0 or 1. We need make sure there are no zeros and ones in our dataset.

#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 2;
#let ncol = 2;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 2, stroke: 0.05em + black),
 table.hline(y: 3, start: 0, end: 2, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 2, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Accuracy], [n],
    ),

    // tinytable cell content after
[0], [9],
[1], [1],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
Number of zeros and ones in our dataset
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-01s>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#link(<tbl-01s>)[Table~1] shows we have 9 rows with accuracy of 0, and 1 row with an accuracy of exactly 1. To run a beta regression we will remove these values.

#block[
```r
#|

#remove 0s and 1s
data_beta <- fluency_data |>
  filter(Accuracy != 0, Accuracy != 1)
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Let's fit the model again with our little .01 and .99 hack. The model object `data_beta` has our accuracy values modified.

#block[
```r
# fit beta model without 0s and 1s in our dataset
beta_model <- glmmTMB(
  Accuracy ~ Fluency,
  disp = ~1,
  data = data_beta,
  family = beta_family(link = "logit")
) # fits a constant for mu and dispersion
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
No errors this time!

=== Model parameters
<model-parameters>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#link(<tbl-beta-cond>)[Table~2] provides a summary of the output for our Beta regression model. The $mu$ parameter estimates, which have the conditional tag in the `Component` column while $phi.alt$ parameter coefficients are tagged as dispersion in the `Component` column).

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
$mu$ component.
]
)
]
#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 3;
#let ncol = 11;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (1, 0), (1, 1), (1, 2), (1, 3), (2, 0), (2, 1), (2, 2), (2, 3), (3, 0), (3, 1), (3, 2), (3, 3), (4, 0), (4, 1), (4, 2), (4, 3), (5, 0), (5, 1), (5, 2), (5, 3), (6, 0), (6, 1), (6, 2), (6, 3), (7, 0), (7, 1), (7, 2), (7, 3), (8, 0), (8, 1), (8, 2), (8, 3), (9, 0), (9, 1), (9, 2), (9, 3), (10, 0), (10, 1), (10, 2), (10, 3),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 11, stroke: 0.05em + black),
 table.hline(y: 4, start: 0, end: 11, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 11, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [z], [df_error], [p], [Component], [Effects],
    ),

    // tinytable cell content after
[(Intercept)], [-0.87], [0.12], [0.95], [-1.105], [-0.63], [-7.2], [Inf], [<.001], [conditional], [fixed],
[FluencyFluent], [0.26], [0.17], [0.95], [-0.067], [0.58], [1.6], [Inf], [0.12], [conditional], [fixed],
[(Intercept)], [6.25], [NA], [0.95], [4.713], [8.28], [NA], [NA], [NA], [dispersion], [fixed],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
Model summary for the mu parameter in beta regression model
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-beta-cond>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#link(<tbl-beta-cond>)[Table~2] displays the summary of the Beta regression model. The first set of coefficients (first two rows in the table) represent how factors influence the $mu$ parameter, which is the mean of the beta distribution. These coefficients are interpreted on the scale of the logit, meaning they represent linear changes on a nonlinear space. The intercept term `(Intercept)` represents the log odds of the mean on accuracy for the disfluent instructor condition. Here being in the disfluent condition translates to a log odds of -0.867. The fluency coefficient `FluencyFluent` represents the difference between the fluency and disfluency conditions. That is, watching a fluent instructor does not lead to higher recall than watching a disfluent instructor, b = 0.259 , SE = 0.166 , 95% CIs = \[-0.067,0.585\], p = 0.12.

#block[
#heading(
level: 
5
, 
numbering: 
none
, 
[
Predicted probabilities.
]
)
]
#block[
```r
# load marginaleffects package
library(marginaleffects)
```

]
#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 2;
#let ncol = 9;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2), (3, 0), (3, 1), (3, 2), (4, 0), (4, 1), (4, 2), (5, 0), (5, 1), (5, 2), (6, 0), (6, 1), (6, 2), (7, 0), (7, 1), (7, 2), (8, 0), (8, 1), (8, 2),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
 table.hline(y: 3, start: 0, end: 9, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Fluency], [estimate], [std.error], [statistic], [p.value], [s.value], [conf.low], [conf.high], [df],
    ),

    // tinytable cell content after
[Disfluent], [0.296], [0.0252], [11.7], [\<0.001], [103], [0.246], [0.345], [Inf],
[Fluent], [0.352], [0.0267], [13.2], [\<0.001], [130], [0.3], [0.405], [Inf],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
Predicted probablities for fluency factor
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-predict-prob>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#link(<tbl-beta-cond>)[Table~2] displays the predicted probabilities for each condition. Both values in the estimate column are negative, which indicates that probability is below 50%. Looking at the predicted probabilities confirms this. For the `Fluency` factor, we can interpret the estimate column in terms of proportions or percentages. That is, participants who watched the fluent instructor scored on average 35% on the final exam compared to 30% for those who watched the disfluent instructor.

We can also easily visualize these from `marginaleffects` using the `plot_predictions` function. To visualize the `mu` parameter set the `what` argument as `mu`.

#block[
```r
beta_plot <- plot_predictions(beta_model, condition = "Fluency", vcov = TRUE)
```

]
#figure([
#box(image("beta_freq_files/figure-typst/fig-plot-pre-1.png"))
], caption: figure.caption(
position: top, 
[
Predicted probablities for fluency factor
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-plot-pre>


#block[
#heading(
level: 
5
, 
numbering: 
none
, 
[
Marginal effects.
]
)
]
#block[
```r
# get risk difference by default
beta_avg_comp <- avg_comparisons(beta_model, variables = "Fluency", dpar = "mu")
```

]
#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 1;
#let ncol = 9;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (1, 0), (1, 1), (2, 0), (2, 1), (3, 0), (3, 1), (4, 0), (4, 1), (5, 0), (5, 1), (6, 0), (6, 1), (7, 0), (7, 1), (8, 0), (8, 1),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
 table.hline(y: 2, start: 0, end: 9, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[term], [contrast], [estimate], [std.error], [statistic], [p.value], [s.value], [conf.low], [conf.high],
    ),

    // tinytable cell content after
[Fluency],
[Fluent \- Disfluent],
[0.057],
[0.036],
[1.6],
[0.119],
[3.1],
[\-0.015],
[0.13],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
Risk difference for fluency
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-ame1>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#link(<tbl-ame1>)[Table~4] displays the risk difference for the fluency factor. The difference between the fluent and disfluent conditions is .06. That is, participants who watched a fluent instructor scored 6% higher on the final recall test than participants who watched the disfluent instructor, b= 0.057, SE = 0.036, 95 % CIs \[-0.015, 0.128 \], p = 0.119.

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Precision ($phi.alt$) component.
]
)
]
The other component we need to pay attention to is the dispersion or precision parameter coefficients labeled as `dispersion` under the `Component` column in #link(<tbl-phi>)[Table~5] the dispersion ($phi.alt$) parameter tells us how precise our estimate is. Specifically, $phi.alt$ in beta regression tells us about the variability of the response variable around its mean. Specifically, a higher dispersion parameter indicates a narrower distribution, reflecting less variability. Conversely, a lower dispersion parameter suggests a wider distribution, reflecting greater variability. The main difference between a dispersion parameter and the variance is that the dispersion has a different interpretation depending on the value of the outcome, as we show below. The best way to understand dispersion is to examine visual changes in the distribution as the dispersion increases or decreases.

Understanding the dispersion parameter helps us gauge the precision of our predictions and the consistency of the response variable. In `beta_model` we only modeled the dispersion of the intercept. When $phi.alt$ is not specified, the intercept is modeled by default.

#block[
```r
# fit beta regression model using betareg

beta_model <- glmmTMB(
  Accuracy ~ Fluency,
  disp = ~1,
  data = data_beta,
  family = beta_family(link = "logit")
)
```

]
#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 1;
#let ncol = 11;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (1, 0), (1, 1), (2, 0), (2, 1), (3, 0), (3, 1), (4, 0), (4, 1), (5, 0), (5, 1), (6, 0), (6, 1), (7, 0), (7, 1), (8, 0), (8, 1), (9, 0), (9, 1), (10, 0), (10, 1),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 11, stroke: 0.05em + black),
 table.hline(y: 2, start: 0, end: 11, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 11, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [z], [dfError], [p], [Component], [Effects],
    ),

    // tinytable cell content after
[(Intercept)],
[6.25],
[NA],
[0.95],
[4.71],
[8.28],
[NA],
[NA],
[NA],
[dispersion],
[fixed],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
Beta model summary output of the $phi.alt$ parameter
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-phi>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We can model the dispersion of the `Fluency` factor---this allows dispersion to differ between the fluent and disfluent conditions. To do this we add a `disp` argument to our `glmmTMB` function call. In the below model, `beta_model_dis`, we model the precision of the `Fluency` factor by using a `~` and adding factors of interest to the right of it

#block[
```r
# add disp/percison for fluency by including factors
beta_model_dis <- glmmTMB(
  Accuracy ~ Fluency,
  disp = ~Fluency, # phi for fluency_dummy
  data = data_beta,
  family = beta_family(link = "logit")
)
```

]
#block[
```r
beta_model_dis_nonexp <- beta_model_dis |>
  model_parameters()
```

]
#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 2;
#let ncol = 11;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2), (3, 0), (3, 1), (3, 2), (4, 0), (4, 1), (4, 2), (5, 0), (5, 1), (5, 2), (6, 0), (6, 1), (6, 2), (7, 0), (7, 1), (7, 2), (8, 0), (8, 1), (8, 2), (9, 0), (9, 1), (9, 2), (10, 0), (10, 1), (10, 2),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 11, stroke: 0.05em + black),
 table.hline(y: 3, start: 0, end: 11, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 11, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [z], [dfError], [p], [Component], [Effects],
    ),

    // tinytable cell content after
[(Intercept)], [1.64], [0.202], [0.95], [1.244], [2.037], [8.11], [Inf], [<.001], [dispersion], [fixed],
[FluencyFluent], [0.43], [0.288], [0.95], [-0.134], [0.994], [1.49], [Inf], [0.135], [dispersion], [fixed],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
position: top, 
[
beta regression model summary for fluency factor with $phi.alt$ parameter
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-phi-beta>


== Zero-inflated beta (ZIB) regression
<zero-inflated-beta-zib-regression>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
A limitation of the beta regression model is it can can only model values between 0 and 1, but not exactly 0 or 1. In our dataset we have 9 rows with `Accuracy` equal to zero.

To use the Beta distribution we removed 0s and 1s--which is never a good idea in practice. In our case it might be important to model the structural zeros in our data, as fluency of instructor might be an important factor in predicting the zeros in our model. Luckily, there is a model called the zero-inflated beta (ZIB) model that takes into account the structural 0s in our data. We'll still model the $mu$ and $phi.alt$ (or mean and precision) of the beta distribution, but now we'll also add one new special parameter: $alpha$.

With zero-inflated regression, we're actually modelling a mixture of the data-generating process. The $alpha$ parameter uses a logistic regression to model whether the data is 0 or not. Substantively, this could be a useful model when we think that 0s come from a process that is relatively distinct from the data that is greater than 0. For example, if we had a dataset of how much teenagers smoke per week, we might want a separate model for the 0s because non-smokers are substantively different in that they never smoke, and first must choose to become smokers before we will record non-zero values.

Below we fit a model called `beta_model_0` using the `glmmTMB` package. In the `glmmTMB` function, we can model the zero inflation by including an argument called `ziformula`. This allows us to model the new parameter $alpha$. Before we fit this model, we remove accuracy values equal to 1.

#block[
```r
# keep 0 but transform 1 to .99
data_beta_0 <- fluency_data |>
  filter(Accuracy != 1)
```

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
After we have done this, let's fit a model using our modified dataset (`data_beta_0` where there is a zero-inflated component for `Fluency`).

#block[
```r
# fit zib modelwith glmmTMB

beta_model_0 <- glmmTMB(
  Accuracy ~ Fluency,
  disp = ~Fluency,
  ziformula = ~Fluency, # add zero inflated component to model
  data = data_beta_0,
  family = beta_family(link = "logit")
)
```

]
=== Model parameters
<model-parameters-1>
#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 6;
#let ncol = 10;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), (6, 6), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 6), (9, 0), (9, 1), (9, 2), (9, 3), (9, 4), (9, 5), (9, 6),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 10, stroke: 0.05em + black),
 table.hline(y: 7, start: 0, end: 10, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 10, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI_low], [CI_high], [z], [df_error], [p], [Component],
    ),

    // tinytable cell content after
[(Intercept)], [-0.835], [0.132], [0.95], [-1.095], [-0.576], [-6.31], [Inf], [p < .001], [conditional],
[FluencyFluent], [0.204], [0.17], [0.95], [-0.129], [0.538], [1.2], [Inf], [0.23], [conditional],
[(Intercept)], [-1.682], [0.385], [0.95], [-2.436], [-0.927], [-4.37], [Inf], [p < .001], [zero_inflated],
[FluencyFluent], [-2.079], [1.082], [0.95], [-4.201], [0.042], [-1.92], [Inf], [0.055], [zero_inflated],
[(Intercept)], [1.64], [0.202], [0.95], [1.244], [2.037], [8.11], [Inf], [p < .001], [dispersion],
[FluencyFluent], [0.43], [0.288], [0.95], [-0.134], [0.994], [1.49], [Inf], [0.135], [dispersion],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-beta-model-zero>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#link(<tbl-beta-model-zero>)[Table~7] provides a summary of the output for our zib model. As before, we can use the `model_paramters` function to extract the relevant coefficients.The $mu$ parameter estimates, which have the conditional tag in the `Component` column are on the logit scale; while $phi.alt$ parameter coefficients (tagged as dispersion in the `Component` column) are on the log scale. In addition, the zero-inflated parameter estimates (tagged as zero-inflated in the `Component` column) are on the logit scale.

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
$mu$.
]
)
]
Looking at the $mu$ part of the model, there is no significant effect for `Fluency`, b = 0.204 , SE = 0.17 , 95% CIs = \[-0.129,0.538\], p = 0.23

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
$alpha$.
]
)
]
However, for the zero-inflated part of the model, the `Fluency` predictor is margianlly significant, b = -2.079 , SE = 1.082 , 95% CIs = \[-4.201,0.042\], p = 0.055.

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
$phi.alt$.
]
)
]
Lastly the dispersion estimate for `Fluency` is significant, b = 0.43 , SE = 0.288 , 95% CIs = \[-0.134,0.994\], p = 0.135.

=== Predicted probabilities and marginal effects
<predicted-probabilities-and-marginal-effects>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Similar to above, we can back-transform our estimates to get probabilities. Focusing on the zero-inflated part of our model (you can use prevuosuly highlighted code to get $mu$ and $phi.alt$), we can use the `avg_predictions` function from `marginaleffects` package. Because we are interested in the zero-inflated part of the model we set the `type` argument to `zprob`.

#block[
```r
beta_model_table <- beta_model_0 |>
  marginaleffects::avg_predictions(by = "Fluency", type = "zprob")
```

]
#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 2;
#let ncol = 2;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 2, stroke: 0.05em + black),
 table.hline(y: 3, start: 0, end: 2, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 2, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Fluency], [estimate],
    ),

    // tinytable cell content after
[Disfluent], [0.1569],
[Fluent], [0.0227],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-predict-zero>


#block[
```r
zob_marg <- beta_model_0 |>
  marginaleffects::avg_comparisons(
    variables = "Fluency",
    type = "zprob",
    comparison = "difference",
  )
```

]
#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 1;
#let ncol = 9;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (1, 0), (1, 1), (2, 0), (2, 1), (3, 0), (3, 1), (4, 0), (4, 1), (5, 0), (5, 1), (6, 0), (6, 1), (7, 0), (7, 1), (8, 0), (8, 1),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 9, stroke: 0.05em + black),
 table.hline(y: 2, start: 0, end: 9, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 9, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[term], [contrast], [estimate], [std.error], [statistic], [p.value], [s.value], [conf.low], [conf.high],
    ),

    // tinytable cell content after
[Fluency],
[Fluent - Disfluent],
[-0.134],
[0.0557],
[-2.41],
[0.016],
[5.97],
[-0.243],
[-0.025],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-marg-zib>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Interpreting the estimates in #link(<tbl-marg-zib>)[Table~9];, seeing lecture videos with a fluent instructor reduces the proportion of zeros by about 13%, which is statistically significant, b = -0.134 , SE = 0.056 , 95% CIs = \[-0.243,-0.025\], p = 0.016. Here we have evidence that participants are more likely to do more poorly (have more zeros) after watching a disflueny lecture.

== Ordered Beta regression
<ordered-beta-regression>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
We can run an ordered beta regression using the `glmmTMB` function and by changing the `family` argument to `ordbeta`.

#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 3;
#let ncol = 11;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (1, 0), (1, 1), (1, 2), (1, 3), (2, 0), (2, 1), (2, 2), (2, 3), (3, 0), (3, 1), (3, 2), (3, 3), (4, 0), (4, 1), (4, 2), (4, 3), (5, 0), (5, 1), (5, 2), (5, 3), (6, 0), (6, 1), (6, 2), (6, 3), (7, 0), (7, 1), (7, 2), (7, 3), (8, 0), (8, 1), (8, 2), (8, 3), (9, 0), (9, 1), (9, 2), (9, 3), (10, 0), (10, 1), (10, 2), (10, 3),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 11, stroke: 0.05em + black),
 table.hline(y: 4, start: 0, end: 11, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 11, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI\_low], [CI\_high], [z], [df\_error], [p], [Component], [Effects],
    ),

    // tinytable cell content after
[(Intercept)], [\-0.9], [0.12], [0.95], [\-1.1309], [\-0.66], [\-7.5], [Inf], [0], [conditional], [fixed],
[FluencyFluent], [0.31], [0.16], [0.95], [\-0.0031], [0.63], [1.9], [Inf], [0.05], [conditional], [fixed],
[(Intercept)], [6.25], [NA], [0.95], [4.72], [8.29], [NA], [NA], [NA], [dispersion], [fixed],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-ordbeta-glmm>


#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Model Parameters.
]
)
]
#block[
#heading(
level: 
5
, 
numbering: 
none
, 
[
$mu$.
]
)
]
If we take a look at the summary output in #link(<tbl-ordbeta-glmm>)[Table~10];, we can interpret the values similar to a beta regression, where the conditional effects are on the log odds scale. Here the `Fluency` parameter is not statistically significant, #emph[p] = .05.

#block[
#heading(
level: 
6
, 
numbering: 
none
, 
[
$phi.alt$.
]
)
]
#link(<tbl-ordbeta-glmm>)[Table~10] also includes an overall $phi.alt$ component. Similar to our other models we can model the variability as a function of fluency.

#figure([
#show figure: set block(breakable: true)

#let nhead = 1;
#let nrow = 4;
#let ncol = 11;

  #let style-array = ( 
    // tinytable cell style after
(pairs: ((0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (6, 0), (6, 1), (6, 2), (6, 3), (6, 4), (7, 0), (7, 1), (7, 2), (7, 3), (7, 4), (8, 0), (8, 1), (8, 2), (8, 3), (8, 4), (9, 0), (9, 1), (9, 2), (9, 3), (9, 4), (10, 0), (10, 1), (10, 2), (10, 3), (10, 4),), ),
  )

  // tinytable align-default-array before
  #let align-default-array = ( left, left, left, left, left, left, left, left, left, left, left, ) // tinytable align-default-array here
  #show table.cell: it => {
    if style-array.len() == 0 {
      it 
    } else {
      let tmp = it
      for style in style-array {
        let m = style.pairs.find(k => k.at(0) == it.x and k.at(1) == it.y)
        if m != none {
          if ("fontsize" in style) { tmp = text(size: style.fontsize, tmp) }
          if ("color" in style) { tmp = text(fill: style.color, tmp) }
          if ("indent" in style) { tmp = pad(left: style.indent, tmp) }
          if ("underline" in style) { tmp = underline(tmp) }
          if ("italic" in style) { tmp = emph(tmp) }
          if ("bold" in style) { tmp = strong(tmp) }
          if ("mono" in style) { tmp = math.mono(tmp) }
          if ("strikeout" in style) { tmp = strike(tmp) }
        }
      }
      tmp
    }
  }

  #align(center, [

  #table( // tinytable table start
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => {
      let sarray = style-array.filter(a => "align" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().align
      } else {
        left
      }
    },
    fill: (x, y) => {
      let sarray = style-array.filter(a => "background" in a)
      let sarray = sarray.filter(a => a.pairs.find(p => p.at(0) == x and p.at(1) == y) != none)
      if sarray.len() > 0 {
        sarray.last().background
      }
    },
 table.hline(y: 1, start: 0, end: 11, stroke: 0.05em + black),
 table.hline(y: 5, start: 0, end: 11, stroke: 0.1em + black),
 table.hline(y: 0, start: 0, end: 11, stroke: 0.1em + black),
    // tinytable lines before

    table.header(
      repeat: true,
[Parameter], [Coefficient], [SE], [CI], [CI\_low], [CI\_high], [z], [df\_error], [p], [Component], [Effects],
    ),

    // tinytable cell content after
[(Intercept)], [\-0.87], [0.13], [0.95], [\-1.126], [\-0.62], [\-6.7], [Inf], [0], [conditional], [fixed],
[FluencyFluent], [0.26], [0.16], [0.95], [\-0.058], [0.59], [1.6], [Inf], [0.11], [conditional], [fixed],
[(Intercept)], [1.65], [0.2], [0.95], [1.262], [2.05], [8.3], [Inf], [0], [dispersion], [fixed],
[FluencyFluent], [0.41], [0.29], [0.95], [\-0.155], [0.97], [1.4], [Inf], [0.16], [dispersion], [fixed],

    // tinytable footer after

  ) // end table

  ]) // end align
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-ordbeta-glmm-disp>


#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Similar to before, including the dispersion parameter introduces more uncertainty into the $mu$ estimate.

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Predicted probabilities and marginal effects.
]
)
]
Remember these values are on the logit scale so we can take the inverse and get predicted probabilities like we have done before using the `marginaleffects` package. These values are shown in #strong[?\@tbl-ordbeta-pred];.

We can get the risk difference as well. These values are in #strong[?\@tbl-ordbeta-risk];.

=== $phi.alt$
<phi-2>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#strong[?\@tbl-ordbeta-summ] also includes an overall phi component. Similar to our other models we can model the variability as a function of fluency. Let's try this in our model: Note the addition of the `phi_reg` argument. This argument allows us to include a model that explicitly models the dispersion parameter. Because I am modeling $phi.alt$ as a function of fluency, I set the argument to `both`

In #strong[?\@tbl-phi-ordbeta];, `b_phi_Fluency_dummy1` is close enough to 0 relative to its uncertainty, we can say that in this case there likely aren't major differences in variance between the fluent disfluent conditions

== XBX Regression
<xbx-regression>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
A new type of regression known as XBX regression can be used for data that contain 0s and 1s.

= References
<references>
#set par(first-line-indent: 0in, hanging-indent: 0.5in)
#block[
] <refs>
#set par(first-line-indent: 0.5in, hanging-indent: 0in)


 
  
#set bibliography(style: "\_extensions/wjschne/apaquarto/apa.csl") 


