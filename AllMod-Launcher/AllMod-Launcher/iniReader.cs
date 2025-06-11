/********************************************************************
  this is a part of sfe2
  Created by MythKAst
  ©2013 MythKAst Some rights reserved.


  You can build it with vs2010,mono
  Anybody who gets this source code is able to modify or rebuild it anyway,
  but please keep this section when you want to spread a new version.
  It's strongly not recommended to change the original copyright. Adding new version
  information, however, is Allowed. Thanks.
  For the latest version, please be sure to check my website:
  https://code.google.com/p/sfe2


  你可以用vs2010,mono编译这些代码
  任何得到此代码的人都可以修改或者重新编译这段代码，但是请保留这段文字。
  请不要修改原始版权，但是可以添加新的版本信息。
  最新版本请留意：https://code.google.com/p/sfe2

 MythKAst(asdic182@sina.com), in 2013 June.
*********************************************************************/
using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
namespace imzopr
{
    using returnDic = Dictionary<string, string>;
    public class inireader 
    {

        Stream filestream = null;
        Dictionary<string, returnDic> returnvalue = null;
        public inireader(Stream fs)
        {
            filestream = fs;
            returnvalue = new Dictionary<string, returnDic>();
            try
            {
                ReadAllsection();
            }
            catch { }
            //returnvalue = new Dictionary<string, string>();
        }
        private void ReadAllsection()
        {
            string tmpstr;
            string tmpsection = string.Empty;
            returnDic tmpDic = new returnDic();
            if (filestream != null)
            {
                StreamReader sr = new StreamReader(filestream, Encoding.Default);
                while (!sr.EndOfStream)
                {
                    tmpstr = sr.ReadLine().Trim().ToLower();
                    if (tmpstr == string.Empty) continue;
                    if (tmpstr[0] == '[' && tmpstr[tmpstr.Length - 1] == ']')
                    {
                        //issection
                        if (tmpsection != string.Empty)
                        {
                            returnvalue.Add(tmpsection, tmpDic);
                        }
                        tmpsection = tmpstr.Substring(1, tmpstr.Length - 2);
                        tmpDic = new returnDic();
                    }
                    else
                    {
                        try
                        {
                            string[] tmpsplit = tmpstr.Split('=');
                            if (tmpsplit.Length > 1)
                            {
                                string[] tmpsplit2 = tmpsplit[1].Split(';');
                                if (tmpsplit2.Length > 1)
                                    tmpDic.Add(tmpsplit[0].Trim().ToLower(), tmpsplit2[0].Trim().ToLower());
                                else
                                    tmpDic.Add(tmpsplit[0].Trim().ToLower(), tmpsplit[1].Trim().ToLower());
                            }
                        }
                        catch { }
                    }
                }
                returnvalue.Add(tmpsection, tmpDic);
                sr.Close();
                sr.Dispose();
            }
        }
        public string ReadIniString(string section, string name, string defaultvalue = "")
        {
            string tmpstr = defaultvalue;
            section = section.ToLower();
            name = name.ToLower();
            if (returnvalue != null)
            {
                try
                {
                    return returnvalue[section][name];
                }
                catch { }
            }
            return tmpstr;
        }
        public int ReadIniInt(string section, string name, int defaultvalue = 0)
        {
            string tmpstr = string.Empty;
            section = section.ToLower();
            name = name.ToLower();
            int returnvalueInt = defaultvalue;
            if (returnvalue != null)
            {
                try
                {
                    if (int.TryParse(returnvalue[section][name], out returnvalueInt))
                        return returnvalueInt;
                }
                catch { }
            }
            return returnvalueInt;
        }
    }
}
