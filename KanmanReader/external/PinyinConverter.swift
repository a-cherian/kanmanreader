//
//  PinyinConverter.swift
//
//  Converted from https://github.com/quizlet/pinyin-converter
//

import Foundation

class PinyinConverter: NSObject {
    
    let pinyinRegex = try! NSRegularExpression(pattern: "(shuang|chuang|zhuang|xiang|qiong|shuai|niang|guang|sheng|kuang|shang|jiong|huang|jiang|shuan|xiong|zhang|zheng|zhong|zhuai|zhuan|qiang|chang|liang|chuan|cheng|chong|chuai|hang|peng|chuo|piao|pian|chua|ping|yang|pang|chui|chun|chen|chan|chou|chao|chai|zhun|mang|meng|weng|shai|shei|miao|zhui|mian|yong|ming|wang|zhuo|zhua|shao|yuan|bing|zhen|fang|feng|zhan|zhou|zhao|zhei|zhai|rang|suan|reng|song|seng|dang|deng|dong|xuan|sang|rong|duan|cuan|cong|ceng|cang|diao|ruan|dian|ding|shou|xing|zuan|jiao|zong|zeng|zang|jian|tang|teng|tong|bian|biao|shan|tuan|huan|xian|huai|tiao|tian|hong|xiao|heng|ying|jing|shen|beng|kuan|kuai|nang|neng|nong|juan|kong|nuan|keng|kang|shua|niao|guan|nian|ting|shuo|guai|ning|quan|qiao|shui|gong|geng|gang|qian|bang|lang|leng|long|qing|ling|luan|shun|lian|liao|zhi|lia|liu|qin|lun|lin|luo|lan|lou|qiu|gai|gei|gao|gou|gan|gen|lao|lei|lai|que|gua|guo|nin|gui|niu|nie|gun|qie|qia|jun|kai|kei|kao|kou|kan|ken|qun|nun|nuo|xia|kua|kuo|nen|kui|nan|nou|kun|jue|nao|nei|hai|hei|hao|hou|han|hen|nai|rou|xiu|jin|hua|huo|tie|hui|tun|tui|hun|tuo|tan|jiu|zai|zei|zao|zou|zan|zen|eng|tou|tao|tei|tai|zuo|zui|xin|zun|jie|jia|run|diu|cai|cao|cou|can|cen|die|dia|xue|rui|cuo|cui|dun|cun|cin|ruo|rua|dui|sai|sao|sou|san|sen|duo|den|dan|dou|suo|sui|dao|sun|dei|zha|zhe|dai|xun|ang|ong|wai|fen|fan|fou|fei|zhu|wei|wan|min|miu|mie|wen|men|lie|chi|cha|che|man|mou|mao|mei|mai|yao|you|yan|chu|pin|pie|yin|pen|pan|pou|pao|shi|sha|she|pei|pai|yue|bin|bie|yun|nüe|lve|lu:e|shu|ben|ban|bao|bei|bai|lüe|nve|nu:e|ren|ran|rao|xie|re|ri|si|su|se|ru|sa|cu|ce|ca|ji|ci|zi|zu|ze|za|hu|he|ha|ju|ku|ke|qi|ka|gu|ge|ga|li|lu|le|qu|la|ni|xi|nu|ne|na|ti|tu|te|ta|xu|di|du|de|bo|lv|lu:|ba|ai|ei|ao|ou|an|en|er|da|wu|wa|wo|fu|fo|fa|nv|nu:|mi|mu|yi|ya|ye|me|mo|ma|pi|pu|po|yu|pa|bi|nü|bu|lü|e|o|a)r?[1-5]", options: .caseInsensitive)
    
    let vowelRegex = try! NSRegularExpression(pattern: ".\\*", options: []) // This might not work
    
    let vowels = [
        "a*": 0,
        "e*": 1,
        "i*": 2,
        "o*": 3,
        "u*": 4,
        "ü*": 5,
        "A*": 6,
        "E*": 7,
        "I*": 8,
        "O*": 9,
        "U*": 10,
        "Ü*": 11
    ]
    
    let pinyin = [
        1: ["ā", "ē", "ī", "ō", "ū", "ǖ", "Ā", "Ē", "Ī", "Ō", "Ū", "Ǖ"],
        2: ["á", "é", "í", "ó", "ú", "ǘ", "Á", "É", "Í", "Ó", "Ú", "Ǘ"],
        3: ["ǎ", "ě", "ǐ", "ǒ", "ǔ", "ǚ", "Ǎ", "Ě", "Ǐ", "Ǒ", "Ǔ", "Ǚ"],
        4: ["à", "è", "ì", "ò", "ù", "ǜ", "À", "È", "Ì", "Ò", "Ù", "Ǜ"],
        5: ["a", "e", "i", "o", "u", "ü", "A", "E", "I", "O", "U", "Ü"]
    ]
    
    var accentMap: [String: String] = [:]
    var accentArray: [[String]] = [] //Swift dictionaries are not ordered by insertion, so we need this to preserve order
    
    override init() {
        super.init()
        self.createAccentMap()
    }
    
    // Splits pinyin into individual syllables: ["ni2", "hao3"],
    // Replaces each component with tone marked version
    func convert(pinyin: String) -> String {
        var converted = pinyin
        let matches = pinyinRegex.matches(in: pinyin, options: [], range: NSRange(location: 0, length: (pinyin as NSString).length)).map {
            (pinyin as NSString).substring(with: $0.range)
        }
        matches.forEach { (match) in
            let replacement = self.getReplacement(match)
            converted = converted.replacingOccurrences(of: match, with: replacement)
        }
        return converted
    }
    
    // Replaces a numbered syllable with the correct accented vowel
    func getReplacement(_ match: String) -> String {
        let tone = Int(match.suffix(1))! // This should always work because all matches end with a number
        let word = String(match.prefix(match.count - 1).replacingOccurrences(of: "v", with: "ü")
                                                       .replacingOccurrences(of: "V", with: "Ü")
                                                       .replacingOccurrences(of: "u:", with: "ü")
                                                       .replacingOccurrences(of: "U:", with: "Ü"))
        for (baseVowelArray) in accentArray {
            let base = baseVowelArray[0]
            let vowel = baseVowelArray[1]
            let offset = word.range(of: base)?.lowerBound.utf16Offset(in: word)
            if (offset != nil && offset! >= 0) {
                let vowelCharMatch = vowelRegex.firstMatch(in: vowel, options: [], range: NSRange(location: 0, length: (vowel as NSString).length))
                let vowelChar = (vowel as NSString).substring(with: vowelCharMatch!.range) // This should always match, so safe to force unwrap
                let vowelNum = vowels[vowelChar]
                let accentedVowelChar = pinyin[tone]![vowelNum!]
                let replacedWord = word.replacingOccurrences(of: base, with: vowel).replacingOccurrences(of: vowelChar, with: accentedVowelChar)
                return replacedWord
            }
        }
        return match
    }
    
    // Creates a map of where to place the tone mark in a syllable
    func createAccentMap() {
        let stars = "a*i a*o e*i ia* ia*o ie* io* iu* " + "A*I A*O E*I IA* IA*O IE* IO* IU* " + "o*u ua* ua*i ue* ui* uo* üe* " + "O*U UA* UA*I UE* UI* UO* ÜE* " + "A* E* I* O* U* Ü* " + "a* e* i* o* u* ü*"
        let nostars = stars.replacingOccurrences(of: "*", with: "")
        let starsArray = stars.split(separator: " ")
        let basesArray = nostars.split(separator: " ")
        basesArray.enumerated().forEach({ (index, base) in
            accentArray.append([String(base), String(starsArray[index])])
            accentMap[String(base)] = String(starsArray[index])
        })
    }
}
