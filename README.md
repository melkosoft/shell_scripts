# shell_scripts - simple bash scripts

1. **convert.sh** - commandline script for batch converting ebooks to pdf|epub|mobi|azw3
             requires Calibre software installed. Accept ebook names through pipe
             (find / -name "*.epub" | convert - will convert epub to pdf)

2. **confluence-backup.sh** - shell script to export Confluence Cloud sites to XML format. 
                          Account used in script has to be site admin