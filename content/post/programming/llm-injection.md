---
title: "Stub: Variational Selector Text Stenography"
date: 2025-08-23T13:58:16-07:00
categories: [programming]
tags: [programming, cybersecurity, ai]
---

This interactive tool converts selected text directly into invisible variation selectors (U+E0100+).

<!--more-->

<div id="surrogate-converter">
  <div style="margin-bottom: 15px;">
    <input type="text" id="textInput" placeholder="Enter text here" style="width: 300px; padding: 5px;">
    <button id="convertBtn" style="padding: 5px 10px; margin-left: 10px;">Convert Selected</button>
  </div>
  
  <div style="margin-bottom: 15px;">
    <textarea id="textOutput" readonly style="width: 400px; height: 100px; padding: 5px; font-family: monospace;"></textarea>
  </div>
  
  <button id="copyBtn" style="padding: 5px 10px;">Copy Output</button>
  <span id="copyStatus" style="margin-left: 10px; color: green; display: none;">Copied!</span>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
  const textInput = document.getElementById('textInput');
  const convertBtn = document.getElementById('convertBtn');
  const textOutput = document.getElementById('textOutput');
  const copyBtn = document.getElementById('copyBtn');
  const copyStatus = document.getElementById('copyStatus');
  
  convertBtn.addEventListener('click', function() {
    const input = textInput.value;
    const selectionStart = textInput.selectionStart;
    const selectionEnd = textInput.selectionEnd;
    
    let result = '';
    
    if (selectionStart !== selectionEnd) {
      // Process with selection: keep unselected parts, convert selected part
      let beforeStart = selectionStart;
      let afterEnd = selectionEnd;
      
      // Prefer trimming space after selection, else trim before
      if (afterEnd < input.length && input[afterEnd] === ' ') {
        afterEnd++;
      } else if (beforeStart > 0 && input[beforeStart - 1] === ' ') {
        beforeStart--;
      }
      
      result += input.substring(0, beforeStart); // Before selection (possibly trimmed)
      
      // Convert selected text (plus trimmed spaces) to variation selectors
      const selectedText = input.substring(beforeStart, afterEnd);

      let internal = ``

      // Encode text as variation selectors
      for (let i = 0; i < selectedText.length; i++) {
        const charCode = selectedText.charCodeAt(i);
        // Map to variation selectors (U+E0100+)
        if (charCode >= 0x20 && charCode <= 0x7E) {
          result += String.fromCodePoint(0xE0100 + charCode);
          internal += String.fromCodePoint(0xE0100 + charCode);
        }
      }
      
      result += input.substring(afterEnd); // After selection (possibly trimmed)

      console.log("before selection", input.substring(0, selectionStart))
      console.log("after selection", input.substring(selectionEnd))
      console.log("internal", internal)
    } else {
      // Convert entire input if nothing selected
      for (let i = 0; i < input.length; i++) {
        const charCode = input.charCodeAt(i);
        if (charCode >= 0x20 && charCode <= 0x7E) {
          result += String.fromCodePoint(0xE0100 + charCode);
        }
      }
    }
    
    textOutput.value = result;
  });
  
  copyBtn.addEventListener('click', function() {
    textOutput.select();
    navigator.clipboard.writeText(textOutput.value).then(function() {
      copyStatus.style.display = 'inline';
      setTimeout(function() {
        copyStatus.style.display = 'none';
      }, 2000);
    });
  });
});
</script>

## Theory

The basic idea is to assume an LLM is smart enough to decode this text even if
its immediately invisible, due to the hex codes at the end being 'aligned' on a
hex boundary with ASCII, and otherwise being essentially unused for any other
purpose.

## Effects

In my testing at the time of writing, ChatGPT can inspect or 'see' the secret
values, but I haven't really had any luck crafting a sufficiently convincing
hidden prompt that will saliently 'override' the visible portions of the prompt.

In the attack scenario that a person is copy/pasting directly into the prompt
text box, it may also be worth obfuscating the visible prompt text with
homoglyphs or intersperse it with no-width spaces, to decrease the corresponding
weight of the visible prompt relative to the hidden one.

## Countermeasures

During post-training, LLM developers should probably be hardening the LLM
against a variety of stenography attacks by giving examples of refusals,
disclosures, or ignores - in addition to checks using traditional code to detect
malformed or suspicious Unicode.
