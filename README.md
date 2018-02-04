Documentazione Blog
===================

Il blog in questione è fatto con [Jekyll](https://jekyllrb.com/) e hostato con GitHub Pages. E' necessario quindi installare localmente la gemma `jekyll`.

Servire il blog localmente
--------------------------

E' possibile servire il blog localmente per avere una preview di ciò che sarà pubblicato con il comando:

```bash
jekyll serve --watch
```

Creare un nuovo post
--------------------

E' presente uno script di utilità per creare un nuovo post in `bin/create_post.sh`. Il suo uso è:

```bash
bash bin/create_post.sh <titolo>
```

Ad esempio:

```bash
bash bin/create_post.sh "Il titolo del mio nuovo post"
```

Le doppie virgolette sono importanti in quanto fanno in modo che tutto il titolo sia considerato.

Creare un nuovo tag
-------------------

E' presente uno script di utilità per creare un nuovo tag in `bin/create_tag.sh`. Il suo uso è:

```bash
bash bin/create_tag.sh <nome_tag>
```

Ad esempio:

```bash
bash bin/create_tag.sh "Il mio nuovo tag"
```

Anche in questo caso le doppie virgolette sono importanti.
