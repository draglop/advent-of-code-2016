#!/bin/sh

CHALLENGE=`basename "$(realpath $0)" .sh`

do_build()
{
    exe_filename=${CHALLENGE}
    source_filename=${exe_filename}.S
    build_command="gcc -O0 -no-pie -Wall -nostdlib ${source_filename} -o ${exe_filename}"
    error_code=0
    if [ ! -e ${exe_filename} ]
    then
        echo ${build_command}
        ${build_command}
        error_code=$?
    else
        source_timestamp=$(stat --printf=%Y ${source_filename})
        exe_timestamp=$(stat --printf=%Y ${exe_filename})
        if [ ${exe_timestamp} -lt ${source_timestamp} ]
        then
            echo ${build_command}
            ${build_command}
            error_code=$?
        fi
    fi

    if [ $error_code -ne 0 ]
    then
        echo "failed to build"
        exit 1
    fi
}

do_clean()
{
    if [ -e ${CHALLENGE} ]
    then
        rm -v ${CHALLENGE}
    fi
}

do_run()
{
    ./${CHALLENGE} "${1}"
}

do_test()
{
    expected="${1}"
    str="${2}"
    if [ "${3}" != "" ]
    then
        str="${str} ${3}"
    fi
    value=$(./${CHALLENGE} "${str}")
    error_code=$?

    if [ $error_code -ne 0 ]
    then
        echo "KO: '${str}'"
        echo "program error code: $error_code"
        echo "program output: ${value}"
        exit 1
    fi

    if [ "$expected" = "$value" ]
    then
        echo "OK: got [${value}]"
    else
        echo "KO: '${str}'"
        echo "expected [${expected}], got [${value}]"
        exit 1
    fi
}

do_test_batch()
{
    do_test "easter" "$(echo -e eedadn\\ndrvtee\\neandsr\\nraavrd\\natevrs\\ntsrnev\\nsdttsa\\nrasrtv\\nnssdts\\nntnada\\nsvetve\\ntesnvt\\nvntsnd\\nvrdear\\ndvrsen\\nenarar)"
    do_test "usccerug" "$(echo -e ewqplnag\\nqchqvvsf\\njdhaqbeu\\njsgoijzv\\niwgxjyxi\\nyzeeuwoi\\ngmgisfmd\\nvdtezvan\\nsecfljup\\ndngzexve\\nxzanwmgd\\nziobunnv\\nennaiqiz\\njgrnzpzi\\nhuwrnmnw\\nqeibstlk\\nqegqmijn\\ngpwfokjg\\ngsmfeqmm\\nhlytxgti\\nidyjagzt\\nmlaztojc\\nxqokrslk\\ngkigkibl\\nfeobhvwi\\nxxylgrpe\\nuivfbbbz\\nlekmcifg\\nngcwvese\\ntgyvzlkg\\npysjumnt\\nbmeepsda\\nsvbznlid\\nhcwlvtyg\\ntjdzsiqu\\ncadtkxut\\nmsirmtzs\\ncxgahqib\\ndtfdkzss\\nnrnodqjy\\nptwvbmtq\\nywkqyulp\\nciszkcnx\\nahxtwnnk\\ndlwvcsfc\\nuewwndje\\nocdgocqk\\nauanolri\\npfqyjyja\\nuypwzjjo\\nzaidpezv\\ntjtwiftf\\nfnrzsyhp\\nhfyqsxfu\\nnigauqsd\\nxonhbtpx\\nwcjciqgn\\nkdgvmzox\\nzbweztcm\\nirrmwyux\\nzmqblmfm\\nchcqxrqm\\nqjnahphi\\nhvkxgyeu\\nuqcsxxix\\nlhzkoydb\\noyukomwi\\nprjjkctn\\nnsjvcthj\\nbivdsubf\\ngalbvbof\\nemrnviig\\nbnpuofwt\\nshsutaeo\\nxkhargbp\\nswunowfn\\ndzohfvtr\\nkbsvqoor\\ndtkjgajx\\nbcjgfstl\\njlgouhim\\nxmbqsvjx\\nbrcvmnqc\\neyphcrec\\nflnxhhzm\\nblrixjdy\\nmsxlfmop\\neaawcbkp\\nmgxiemxl\\npfxtpuvh\\nvulefkxn\\ntlxfigbc\\niktsstzd\\nqdycwpat\\nyjfhllyu\\nmmcxxloe\\nxpwpjnuy\\nsziveuyv\\nrmkmyqyl\\nhqywtzhu\\npouceqty\\nkvfdzahj\\nltiledbc\\npcajwpht\\nkcsxqksn\\nbfmdmqyf\\nluxbaaqq\\nnptsvniz\\naawfrzxw\\nkeeyyptq\\nryicuhie\\nyjvclzac\\nbveorbeo\\nohmbvpmu\\ncvxejdwb\\nziyffdnx\\ngwjxdbaq\\nunnrfnqh\\nkvicaaai\\njkkiuvxj\\ncjviyayl\\ndrbielvb\\nnulynluk\\neixugugc\\nfxfzuonn\\nludhzktb\\ntmqvbqfm\\nnzzjdxph\\nukzvvges\\nejplrckc\\nocawtnmd\\nsvqsxbrf\\nsfdfgohg\\nbnjrokxk\\nfrulcpng\\nfjuhbzfb\\nwpwytpzh\\njqstbhff\\nwkzichey\\nuygpxxgb\\nlaemchta\\nvgjcyumm\\nhhloaorn\\niviwosqf\\nkudumnei\\nntfvtoay\\nxcimluam\\nwypytwno\\ncqboftdd\\nmwfcdwzw\\ntgwmjxfp\\njysdwspw\\ncnsoamld\\nfyznzrpo\\nskvorpwt\\nplpwsuih\\naysqbwem\\nrutkdrnn\\nllxxyaqe\\nvfhsvtxv\\nlgtmtjmj\\nypfcjnbb\\ntdvnfrtv\\nobpdwotj\\nzreanciv\\nmfexhuff\\nhodukcbc\\nrjqrgxgn\\nxpmtiaec\\nroavlcvt\\nrabhqwct\\nojkdtbsz\\npztezpmw\\nqefgwtbf\\nocdtbmop\\ndlfgvkmh\\nddpzjrqc\\nounagflg\\nvrtrakwj\\nekcrcvtl\\nhrvghvmq\\nyphmhigf\\nnbmwllxs\\ngmcfdvvw\\nyafshyuo\\nhpbrminb\\nlwmuprvy\\nrajyhedj\\nqtrxbxal\\nwcqfjvfg\\npvzefquu\\njuizosne\\nqbnrfgpp\\nmuyjpylx\\nljftujim\\nssrjqzhi\\nisolpxai\\nlpazyyse\\nznrlwzhc\\ntvcbgplx\\necdcsjuq\\naxzsjwnm\\nedogmygw\\ngfbqksky\\nbekioiyr\\nnyhxmwmx\\nmurhyrrk\\nrwlfdeve\\ntrlmfwjy\\nzzanjgdz\\nbwscvdxk\\ntsmrttcq\\nfmmizwrz\\ncqneezoq\\ndhuwkslc\\njwzrdomv\\nwxrleoed\\nfivvxash\\nioygsjhc\\nqdpwprez\\ntagvmlbn\\npqtaqcot\\nbdmdrheh\\npfmsjlpa\\nhiafczzf\\novjrntwt\\neoytrczw\\nekcuhuur\\nwmqzzebk\\nawczvbtm\\nvnxrniiy\\nkaayoxlt\\nxhjtpiju\\nceffyfww\\nvdnoycxw\\npmebcukw\\nswbogemw\\naffewhdj\\ninbpzraz\\nttjkvylh\\nkhiljslo\\nixmjrdom\\nwfnmgcqr\\npntkncna\\nezbtngtx\\ndxgoiwtq\\ngcorhdwq\\nmtnxxcfn\\nlguoqhpp\\nmydgtldv\\ndcautedv\\naqxafodz\\nabvyoomx\\nqdpyeshc\\neslyxatb\\nsxhhruer\\nfyudfdpl\\nmvbfwmhk\\nupmzmdmz\\nrqxugbwh\\nlubhqmre\\nvhpzyerz\\nljyexgma\\nvpshuvyr\\npxvuccyv\\nppesevpl\\nmjcyazgy\\nmthxasgs\\nzkeinsxs\\nemehvnsz\\nicawtxzi\\nrxrpyaji\\njxoxevxd\\nadewmqba\\njcypwkfv\\nwspbxbnf\\nsjagbbna\\nubfllkvq\\nhsecqidv\\nbztzbswf\\nudhthpya\\nhbpqvrrg\\nglnwntfm\\nghpsmdjt\\nfgwxpvkx\\nsadgtywm\\nipcrkfuv\\ntctyqmko\\nlivzojbr\\nyejzdarn\\naqqnctjm\\nemgcphcq\\nnkqfubfl\\nqojeklqt\\nkvsnebgk\\nwhbowpmx\\nbrmttrog\\ndyecglha\\nbjhyzrqq\\nvtkhzeyk\\nloopqwmv\\npycecyfy\\nriswpqzb\\nfpukakic\\njbyjandt\\npgmqyhho\\nrkovglxj\\ngyoamarg\\nzffmcdgz\\nvajaeirw\\nmewxbrpv\\nakullmcy\\nhnhhlxto\\nvrzuwzzd\\noqudtfol\\nhjbadzse\\npttmnoan\\nbgvmjudu\\ncfrowrpy\\nxapmrpde\\nuvoxhgwo\\nogzbapqj\\nslkplnas\\nnzidxmos\\nymfjsfcx\\ncelkhenj\\nmjsysfzp\\npiduvvdb\\njhjlhnai\\nvuqwliaq\\nkwxnhphe\\nkttkiutd\\nkbxdqmdi\\nsyokthzk\\nhgzkmhvv\\nzhwusjfg\\nqsozuerb\\nobyswgci\\naosbzjnt\\nvtriuhuy\\newwggfad\\nntpassqj\\nggvooetp\\nhhmyywmv\\nrzhrqkvx\\nzapkliel\\nmfrgyvgw\\nziwaqzun\\nvdpqztyc\\nwgxbjzxa\\nazvotolg\\nnskteyaj\\nmxoustqy\\nwfsrmtrk\\nxoqecgrl\\ndluzpwur\\nlokaxykx\\nxyqouhxb\\nudaqkoqf\\nhbvsdvkk\\nomqymecg\\nzpdwrwin\\ngaaprkiw\\nqrljdsgr\\nyzqzxlsu\\nlwxzzesm\\nfogpmgrb\\nahahsyet\\nxbshcjlp\\nkqjnqfns\\ndirbsjvo\\nivvuvzde\\nuuktpjjo\\nxjyqnzuz\\ngocimeia\\nqgznojog\\ngliwbekp\\nbqgakwkl\\nemewklsz\\nnrsbhxls\\nksqxptkx\\nqayiikzs\\nypulgpll\\nzpgbguze\\noxttgrkk\\nusubcozu\\nvfdfaqdf\\naijdqnws\\nzrafskka\\nqevegolp\\nlimniayp\\nufiiffly\\nnpadruup\\neuamdite\\nplzaivpj\\nakqqvlro\\nfoknpolu\\nyzvvtjwz\\nsvhqjfpq\\nzsceoycs\\nfueralpo\\ndmwobiiv\\nnwmjvxxj\\nqvypxtyn\\nycfkrxge\\nbdlrfvxh\\nilkjiske\\nnebvkegk\\nstclxlsh\\ndzcomxfy\\nxnqqcilu\\nfwtpdqok\\nxcwpngxi\\njhzgpgmd\\ngxfgyecr\\nifzqihyl\\nrtdjzika\\neeqqbdrn\\nbcxcqoif\\nsxdiaauc\\nrwfkuhka\\nabixxudr\\naexxbgvm\\nibnckfvl\\nwpnguagh\\nukicjzms\\nrjcdglsa\\nwbbbwedq\\ngszpbdcd\\nuuliinia\\noroolcgs\\ndbrutctl\\nclhhguog\\njhttewcr\\nnudiqqvi\\nonpwamga\\nkztklrsm\\nmoqperyh\\nwrlcyfwl\\nhsnkrqrz\\njctpxrsp\\ndgyjdbaj\\nyxamrvae\\ncubkcqah\\nyvecuhqs\\nvvbcmhdf\\nmcosktuq\\nuonxvxhd\\nzileeeyl\\njxebsrqb\\nrvkudgsu\\nyiflvdar\\nhefezoyf\\nvlhprvnx\\ngnlmhfzj\\nfdzgbpei\\nevisboku\\neiultlcz\\nttrpqdch\\nbnujwmwg\\nkxkijfkb\\nfrzqsuvg\\nyzbrwmhf\\ntbytnypt\\nwizbqixp\\nsqofdzfw\\ngkiddyod\\ntqzyncjl\\nvfsjagyy\\nxkcvhice\\nnkkipbzd\\nmurubxvr\\naalgekbr\\nqzhgpqiz\\nrtxmuasx\\nvznzbbuq\\nbdpaucup\\nbyzeajgv\\ndpedjbke\\nksmynpqq\\nzocacvlb\\nzymffjwb\\ncegodbwk\\nqggqsxoo\\nuziyisoh\\noatngkya\\ncaumywbn\\nlqbnhdpj\\nfszkqnop\\ntnhssbbg\\njyltqque\\nuwwsazxg\\nmwujixlj\\nwrslfkst\\nshmhlagd\\nrgdphggr\\nkorsrnbu\\nrzjnunxy\\nrnjypyeo\\ngtvnifwz\\nuapadqvb\\novipnngd\\ndkehomjw\\neaiejnmq\\njeikkciu\\noftckfsk\\nklydfonj\\nigglmwfo\\nfyubwdnh\\nngzkhkpd\\nyuglfalc\\njhjuufhh\\ndxemyuqq\\nskxsfkuf\\nbngixdvm\\nibetxweu\\nvhkddick\\nyphvckps\\nvsfjvfuc\\nyslnkljn\\nowpmzvtw\\nhwqxmdkm\\nxedywgaa\\ngxspaddo\\nfgtuqtzz\\nlmdgicyj\\nwormnkqh\\nodjjjnjs\\nupwsehpy\\ncdnoenbr\\npalgbqbo\\ncxhtopct\\natyclmda\\nsqqsghaw\\nkphxnffp\\nsnajohsd\\nfgoqdmya\\nqukeyclq\\nridnraeu\\nxxnrgycg\\nithdkict\\nxkkvoupr\\njdxzaowb\\nwsrakjua\\ntnlfvefb\\ntkopftbw\\nfflhizvk\\nqlviiyxs\\ntqlkpdji\\nwbkizspo\\nqfcnlwzy\\nicnypchf\\nrmcrtzhx\\nibghzcrx\\nnwjeakcj\\nozubzsep\\nthevuhvq\\ndrmvjqbr\\nzlsxyeqi\\nkfbaywmd\\nuxpkilwv\\nnifwejqs\\nyjlhwrhl\\njsotkgry\\ntnjboxch\\nloaljerf\\nhowfiujr\\nzmqsffwn\\nuqrsbamt\\nothunkcr\\nylhkojxs\\nkzldescv\\nirwynsjs\\ncytlwbvv\\niqvupsei\\nwemgrrnj\\nakrqrpis\\nvocnluer\\nwjnscmyh\\nhekwlgim\\nilmqutgu\\nqtnurohl\\ncjuclgbg\\nyivdapow\\njrbhdxku\\nxholfbuw\\ngrgfxaho\\nlquojibn\\ncbdendkb\\nmdurkdvz\\ndqdixboo\\nwvopazpt\\nxbxclroc\\nzjxgejjk\\ntmbfyyvz\\ncosjhwru\\naqwtipsw\\npmympjrh)"
}

if [ $# -eq 0 ]
then
    do_build
    do_test_batch
elif [ "$1" = "clean" ]
then
    do_clean
else
    do_build
    for i in "$@"
    do
        do_run "$i"
    done
fi
