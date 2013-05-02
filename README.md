tode-web
========

A short example of how to format text


```smalltalk
|txt win morph|
txt := Text string: 'Some text in green' attributes: {TextEmphasis bold. TextEmphasis italic. TextColor green. TextEmphasis underlined.}.
morph := PluggableTextMorph new.
morph setText: txt.
win := SystemWindow new.
win addMorph: morph frame:(0@0 extent: 1@1).
win openInWorld
```
