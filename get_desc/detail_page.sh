#!/bin/bash
# FileName: get_desc/detail_page.sh
#
# Author: rachpt@126.com
# Version: 2.0v
# Date: 2018-06-10
#
#-------------------------------------#
get_source_site()
{
    tracker_source_infos=`"$trans_show" "$torrentPath" |grep -A 5 'TRACKERS'`

    if [ "`echo $tracker_source_infos|grep -i 'hdsky'`" ]; then
        source_site_URL='https://hdsky.me'
        cookie_source_site="$cookie_hds"
    elif [ "`echo $tracker_source_infos|grep -i 'totheglory'`" ]; then
        source_site_URL='https://totheglory.im'
        cookie_source_site="$cookie_ttg"
    elif [ "`echo $tracker_source_infos|grep -i 'hdchina'`" ]; then
        source_site_URL='https://hdchina.org'
        cookie_source_site="$cookie_hdc"
    #elif [ "`echo $tracker_source_infos|grep -i 'new'`" ]; then
    #    source_site_URL='https://new.tracker.com'
    fi
}
set_source_site_cookie()
{
    if [ "$source_site_URL" = "https://hdsky.me" ]; then
        cookie_source_site="$cookie_hds"
    elif [ "$source_site_URL" = "https://totheglory.im" ]; then
        cookie_source_site="$cookie_ttg"
    elif [ "$source_site_URL" = "https://hdchina.org" ]; then
        cookie_source_site="$cookie_hdc"
    fi
}

#-------------------------------------#
form_source_site_get_tID()
{
    if [ "$source_site_URL" = "https://totheglory.im" ]; then
        source_site_search_URL="${source_site_URL}/browse.php?c=M&search_field=${new_torrent_name}"
    else
        source_site_search_URL="${source_site_URL}/torrents.php?search=${new_torrent_name}"
    fi
    source_t_id=`http "$source_site_search_URL" "$cookie_source_site"| grep 'hit=1'|grep 'id='|head -n 1|awk -F '?id=' '{print $2}'|awk -F '&' '{print $1}'`

}

#-------------------------------------#
form_source_site_get_Desc()
{
    form_source_site_get_tID
    
    if [ -n "${source_t_id}" ]; then
        source_detail_html=`mktemp "${AUTO_ROOT_PATH}/tmp/detail_html.XXXXXXXX"`
        source_detail_desc=`mktemp "${AUTO_ROOT_PATH}/tmp/detail_desc.XXXXXXXX"`
        
        http --ignore-stdin GET "${source_site_URL}/details.php?id=${source_t_id}" "$cookie_source_site" > "$source_detail_html"   
    fi
    
    if [ -s "$source_detail_html" ]; then
       source_start_line_html=`egrep -n '简介|简述' "$source_detail_html" |head -n 1|awk -F ':' '{print $1}'`
        if [ "$source_site_URL" = "https://totheglory.im" ]; then
            source_end_line_html=`grep -n '</div></td></tr>' "$source_detail_html" |head -n 1|awk -F ':' '{print $1}'`
        else
            source_end_line_html=`grep -n '</div></td></tr>' "$source_detail_html" |head -n 2|tail -n 1|awk -F ':' '{print $1}'`
        fi
    
        sed -n "${source_start_line_html},${source_end_line_html}p" "$source_detail_html" > "$source_detail_desc"
        #---hdsky---#
        sed -i 's#.*lt="ad" /></a></div>##' "$source_detail_desc"
        sed -i 's#^[ \t]\+<img#<img#g' "$source_detail_desc"
        #---ttg---#
        sed -i "/\/pic\/ico/d" "$source_detail_desc"
        sed -i "s/.*align=left><div id='kt_d'>//g" "$source_detail_desc"
        
        #---hdc poster---#
        if [ "$source_site_URL" = "https://hdchina.org" ]; then
            source_hdc_poster_img=`grep 'poster_box' "$source_detail_html"|sed "s/.*img src=\"\(http.*\)\"\/.*/\1/"`
            if [ ! "`grep "$source_hdc_poster_img" "$source_detail_desc"`" ]; then
                sed -i "1i <img src=\'$source_hdc_poster_img\' />" "$source_detail_desc"
            fi
        fi
        sed -i "s/[　]*<br \/>/<br \/>/;s/\(..*\).br.*/\1/; s/&nbsp;/　/g" "$source_detail_desc"
        
        imdbUrl="$(grep -o 'tt[0-9]\{7\}' "$source_detail_html"|head -n 1)"
        echo 1:"$imdbUrl" >> "$log_Path"
        #---html2bbcode---#
	    source "$AUTO_ROOT_PATH/get_desc/html2bbcode.sh"
    fi
    rm -f "$source_detail_html"
    source_detail_html=''
}
#-------------------------------------#
if [ -z "$source_site_URL" ]; then
	get_source_site
else
    set_source_site_cookie
fi

if [ "$source_site_URL" = "https://hdsky.me" ]; then
    #---use rss page first---#
    source "$AUTO_ROOT_PATH/get_desc/hdsky_rss.sh"
else
    form_source_site_get_Desc
fi

