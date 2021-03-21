---
title: "Contact"
date: 2019-01-26T12:14:54-05:00
menu: main
authorbox: false
---

You can contact me using the below form. If it's more convenient, I can also be
contacted on [Github](https://github.com/poteat) or
[LinkedIn](https://www.linkedin.com/in/mpoteat-o/).

2021 Update: I have no idea if the below form works. YMMV. Best to just email me.

<!-- Simple obfuscation -->
<script>
f = (s) => {return s.replace(/[a-zA-Z]/g,function(c){return String.fromCharCode((c<="Z"?90:122)>=(c=c.charCodeAt(0)+13)?c:c-26);});}
window.onload = () => {document.getElementById("contact-form").action += f("zr@zcbgr.ng")};
</script>

<form action="https://formspree.io/" method="POST" id="contact-form">
<input type="hidden" name="_subject" value="Contact submission from mpote.at"/>

<b><label for="email">Your Email</label></b><br>
<input id="email" type="email" name="_replyto" placeholder="jsmith@foobar.com"><br><br>

<b><label for="name">Your Name</label></b><br>
<input id="name" type="name" name="name" placeholder="John Smith"><br><br>

<b><label for="message">Message</label></b><br>
<textarea id="message" name="message" placeholder="Blah blah blah..." style="height:200px"></textarea><br><br>

<input type="submit" value="Send">
</form>
