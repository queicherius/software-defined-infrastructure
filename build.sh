cat style.md > full-document.md
echo "\n" >> full-document.md
cat dns.md >> full-document.md
echo "\n\n" >> full-document.md
cat ldap.md >> full-document.md
echo "\n\n" >> full-document.md
cat apache.md >> full-document.md
echo "\n\n" >> full-document.md
cat smb.md >> full-document.md
# echo "\n\n" >> full-document.md
# cat mail.md >> full-document.md
echo "\n\n" >> full-document.md
cat nagios.md >> full-document.md
scholdoc full-document.md > index.html
