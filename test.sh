#!/bin/bash

bundle exec ruby RagService.rb https://flowbite.com/docs/sitemap.xml 'flowbite_components' 'components' '<main[^>]*>' '</main>'