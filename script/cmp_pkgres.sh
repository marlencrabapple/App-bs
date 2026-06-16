expac_pkgbase=($(expac -S '%e' "${inpkg[@]}"))                                                                                           bs_pkgbase=("$(pkgbase "${inpkg[@]}")")                                                                                                                                                                                                                                             function print_section_delim {                                                                                                             typeset section_bound=""                                                                                                                 typeset i=0 
 
  while [[ "${i:-0}" -lt 80 ]]; do                                                                                                           section_bound+="=" 
    i="$(( i + 1 ))" 
  done; 
 
  echo -e "\n$section_bound" 
} 
 
inpkg_abbr="${inpkg[@]:0:3} ... ${inpkg[@]:${#inpkg[@]}:1}: " 
 
print_section_delim 
 
echo "expac -S '%e' $inpkg_abbr" 
echo -e "  ${expac_pkgbase[@]}\n\n" 
 
echo "pkgbase $inpkg_abbr" 
echo -e "  ${bs_pkgbase[@]}\n" 
print_section_delim 
