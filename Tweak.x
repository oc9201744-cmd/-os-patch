Run # -j$(sysctl -n hw.ncpu) komutu derlemeyi tüm çekirdekleri kullanarak hızlandırır
==> Notice: Build may be slow as Theos isn’t using all available CPU cores on this computer. Consider upgrading GNU Make: https://theos.dev/docs/parallel-building
> Making all for tweak AnoBypass…
==> Preprocessing Tweak.x…
==> Preprocessing Tweak.x…
==> Compiling Tweak.x (arm64e)…
==> Compiling Tweak.x (arm64)…
Tweak.x:9:11: error: type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]
    9 | __int64Tweak.x:9: (*orig_sub_F012C)(vo11i:d  error: type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]
*a1);
          | 9 |           ^_
_i      n| t6         int4
 (*orig_sub_F012C)(void *a1);
      |           ^
      |          int
Tweak.x:9:1Tweak.x:: 9:1error: : type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]
    9 | __int64 (*orig_sub_F012C)(void *a1)error: type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]
    9 | __int64 (*orig_s;
      | ^
      | int
ub_F012C)(void *a1);
      | ^
      | int
Tweak.x:9:9Tweak.x:9:9: error: function cannot return function type 'int (void *)':
 error:     function cannot return function type 'int (void *)'9 | 
__int64 (    *9o | r_i_gi_nstu6b4_ F(0*1o2rCi)g(_vsouibd_ F*0a112)C;)(
v      o| id        ^ 
*a1);
      |         ^
Tweak.x:10:1: Tweak.x:10:1:error: unknown type name '__int64'
   10 | __int64 hook_sub_F012 Cerror: unknown type name '__int64'
   10 | __int64 ho(void *a1) {o
      | k_^s
ub_F012C(void *a1) {
      | ^
Tweak.x:17:34: Tweak.xerror: :17:unknown type name '__int64'34:
 error: unknown type name '__int64'
   17 | unsi   g17n | eudn scihganre*d  (c*hoarri*g _(s*uobr_iFg8_3s8uCb)_(F_8_3i8nCt)6(4_ _ai1n,t 6_4_ ian1t,6 4_ _(i*n*ta624) (()*,* au2n)s(i)g,n eudn s_i_ginnetd6 4_ _ai3n,t 6_4Q WaO3R,D  _*QaW4O)R;D 
*      a| 4)                                 ^;

      |                                  ^
Tweak.x:17:57: error: type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]
   17 | unsiTweak.xg:n17e:d57 :c harerror: * (type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]*o
rig_sub_F838C)(__int64 a1, __int64 (**a2)(), unsigned __int64 a3, _QWORD *a4)   17 | unsigned char;*
      |                                                         ^
      |                                                       int 
(*orig_sub_F838C)(__int64 a1, __int64 (**a2)Tweak.x(:)17,: 46u:n sigerror: nedtype specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int] _
_int64    a173 | ,u n_sQiWgOnReDd  *cah4a)r;* 
(      *| or                                                        ^i
g_      s| ub                                                      int
_F838C)(__int64 a1, __int64 (*Tweak.x*:a172:)46(:) , uerror: nsitype specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]gn
ed __int64 a3, _QWO   R17D |  u*nas4i)g;ne
d       | ch                                             ^a
r*       | (*                                             into
rig_sub_F838C)(__int64 a1, __Tweak.xi:n17t:6544:  (**error: a2)function cannot return function type 'int ()'()
, unsi   g17n | eudn s_i_ginnetd6 4c haa3r,*  _(Q*WoOrRiDg _*sau4b)_;F8
3      8| C)                                             ^(
__      i| nt                                             int6
4 a1, __int6Tweak.x:17:54: error: function cannot return function type 'int ()'
   17 | un4 (**a2)(), unsigned __int64 a3, _QWORD *a4);
      |                                                      ^
signed char* (*orig_sub_F838C)(__int64 a1, __int64 (**a2)(), unsigned __int64 a3, _QWORD *a4);
      |                                                      ^
Tweak.x:17:73: error: redefinition of parameter '__int64'
Tweak.x:17:   7317: |  unserror: ignredefinition of parameter '__int64'ed
 char*    17( | *uonrsiigg_nseudb _cFh8a3r8*C )((*_o_riingt_6s4u ba_1F,8 3_8_Ci)n(t_6_4i n(t*6*4a 2a)1(,) ,_ _uinnsti6g4n e(d* *_a_2i)n(t)6,4  uan3s,i g_nQeWdO R_D_ i*nat46)4; a
3      ,|  _                                                                        ^Q
WORDTweak.x :*17a:446):; 
      note: | previous declaration is here                                                                        ^

Tweak.x:17   :1746 | :u nsinote: gnprevious declaration is hereed
 char   *17  | (u*nosriiggn_esdu bc_hFa8r3*8 C()*(o_r_iign_ts6u4b _aF18,3 8_C_)i(n_t_6i4n t(6*4* aa21),( )_,_ iunnts6i4g n(e*d* a_2_)i(n)t,6 4u nas3i,g n_eQdW O_R_Di n*ta644) ;a3
,       | _Q                                             ^W
ORD *a4)Tweak.x;:17
:      81| :                                              ^
error: expected ')'Tweak.x
:17:81:   17 | unsigned char* (*or ig_error: subexpected ')'_F
838C)(   _17_ | iunnts6i4g nae1d,  c_h_airn*t 6(4* o(r*i*ga_2s)u(b)_,F 8u3n8sCi)g(n_e_di n_t_6i4n ta614,  a_3_,i n_tQ6W4O R(D* **aa24))(;),
       u| ns                                                                                ^i
gneTweak.xd: 17_:_33i:n t64note:  ato match this '('3,
 _QWO   R17D |  u*nas4i)g;ne
d       | ch                                                                                ^a
r* (Tweak.x*:o17r:i33g:_ subnote: _Fto match this '('83
8C)(_   _17i | nutn6s4i gan1e,d  _c_hianrt*6 4( *(o*r*iag2_)s(u)b,_ Fu8n3s8iCg)n(ed __int64 a3, _QWORD *a4);
      |                                 ^
__int64 a1, __int64 (**a2)(), unsigned __int64 a3, _QWORD *a4);
      |                                 ^
Tweak.x:18:31: error: unknown type name '__int64'
   18 | unsigned char* hook_sub_F838C(__int64 a1, __int64 (**a2)(), unsigned __int64 a3, _QWORD *a4) {
      |                               ^
Tweak.x:18:54: error: type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]
   18 | unsigned char* hook_sub_F838C(__int64 a1, __int64 (**a2)(), unsigned __int64 a3, _QWORD *a4) {
      |                                                      ^
      |                                                    int
Tweak.xTweak.x::1818::3143::  error: error: unknown type name '__int64'type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]

   18    | 18u | nusnisgingende dc hcahra*r *h ohooko_ks_usbu_bF_8F3883C8(C_(__i_nitn6t46 4a 1a,1 ,_ __i_nitn6t46 4( *(**a*2a)2())(,) ,u nusnisgingende d_ __i_nitn6t46 4a 3a,3 ,_ Q_WQOWRODR D* a*4a)4 ){ {
      
|       |                                           ^
                              ^
      |                                           int
Tweak.x:18:51: error: function cannot return function type 'int ()'
   18Tweak.x | :u18n:s54i:g nederror:  chtype specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]ar
* hook   18 | unsigned char* hook_sub_F_8s3u8bC_(F_8_3i8nCt(6_4_ ian1t,6 4_ _ai1n,t 6_4_ i(n*t*6a42 )((*)*,a 2u)n(s)i,g nuends i_g_niendt 6_4_ ian3t,6 4_ QaW3O,R D_ Q*WaO4R)D  {*a
4      )|  {                                                     ^

            | |                                                   ^                                                   int

Tweak.x:18:70: error: Tweak.x:redefinition of parameter '__int64'18:
43: error:    18 | type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]un
signed   18 | unsigned char char* hook_sub_F838C(* hook_sub_F838C_(__i_nitn6t46 4a 1a,1 ,_ __i_nitn6t46 4( *(**a*2a)2())(,) ,u nusnisgingende d_ __i_nitn6t46 4a 3a,3 ,_ Q_WQOWRODR D* a*4a)4 ){ {

            | |                                                                      ^                                          ^

      |                                           int
Tweak.x:18:43: note: Tweak.x:18:51: error: function cannot return function type 'int ()'
previous declaration is here   18
 | unsigned    18c | huanrs*i ghnoeodk _cshuabr_*F 8h3o8oCk(__s_uibn_tF6843 8aC1(,_ __i_nitn6t46 4a 1(,* *_a_2i)n(t)6,4  u(n*s*iag2n)e(d) ,_ _uinnsti6g4n ead3 ,_ __iQnWtO6R4D  a*3a,4 )_ Q{WO
R      D|  *                                                  ^a
4) {
      |                                           ^
Tweak.x:18:70: Tweak.x:18error: :78:redefinition of parameter '__int64' 
error: expected ')'   18
 | unsig   n18e | du ncshiagrn*e dh ocohka_rs*u bh_oFo8k3_8sCu(b___Fi8n3t86C4( _a_1i,n t_6_4i nat16,4  _(_*i*nat26)4( )(,* *uan2s)i(g)n,e du n_s_iignnte6d4  _a_3i,n t_6Q4W OaR3D,  *_aQ4W)O R{D 
*      a| 4)                                                                     ^ 
{
Tweak.x      :| 18:                                                                             ^43
: note: previous declaration is here
   18 | unsigneTweak.xd: 18c:h30a:r * hnote: ooto match this '('k_
sub_F   18 | unsigned char* 8h3o8oCk(__s_uibn_tF6843 8aC1(,_ __i_nitn6t46 4a 1(,* *_a_2i)n(t)6,4  u(n*s*iag2n)e(d) ,_ _uinnsti6g4n ead3 ,_ __iQnWtO6R4D  a*3a,4 )_ Q{WO
R      D|  *                                          ^a
4) {
Tweak.x      :| 18:                             ^78
: error: expected ')'
   18 | unsigned char* hook_sub_FTweak.x8:3188:C70(:_ _inerror: t64omitting the parameter name in a function definition is a C23 extension [-Werror,-Wc23-extensions] a
1, __   i18n | tu6n4s i(g*n*ead2 )c(h)a,r *u nhsoiogkn_esdu b___Fi8n3t86C4( _a_3i,n t_6Q4W OaR1D,  *_a_4i)n t{64
       (| **                                                                             ^a
2)(Tweak.x):,18 :u30n:s ignnote: edto match this '(' _
_int6   418  | au3n,s i_gQnWeOdR Dc h*aar4*)  h{oo
k      _| su                                                                     ^b
_F838C(__int64 a1, __int64 (**a2)(), unsigned __int64 a3, _QWORD *a4) {
      |                              ^
Tweak.x:18:70: error: omitting the parameter name in a function definition is a C23 extension [-Werror,-Wc23-extensions]
   18 | unsigned char* hook_sub_F838C(__int64 a1, __int64 (**a2)(), unsigned __int64 a3, _QWORD *a4) {
      |                                                                      ^
Tweak.x:25:11: error: type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]
   25 | __int64 (*orig_sub_11D85C)(__int64 a1, __int64 Tweak.xa:225,: 11_:_ interror: 64 type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int [-Wimplicit-int]a3
, __in   t256 | 4_ _ai4n,t 6.4. .()*;or
i      g| _s          ^u
b_      1| 1D         int8
5C)(__int64 a1, __int64 a2, __int64 a3, __int64 a4, ...);
      |           ^
      |          int
Tweak.x:25:28: error: unknown type name '__int64'
   25 | __int64 (*orig_sub_11D85C)(__int64 a1, __int64 a2, __int64 a3, __int64 a4, ...);
      |                            ^
Tweak.x:25:28: error: unknown type name '__int64'
   25 | __int64 (*orig_sub_11D85C)(__int64 a1, __int64 a2, __int64 a3, __int64 a4, ...);
      |                            ^
fatal error: too many errors emitted, stopping now [-ferror-limit=]
fatal error: too many errors emitted, stopping now [-ferror-limit=]
20 errors generated.
20 errors generated.
make[3]: *** [/Users/runner/work/-os-patch/-os-patch/.theos/obj/arm64e/Tweak.x.6aca725a.o] Error 1
rm /Users/runner/work/-os-patch/-os-patch/.theos/obj/arm64e/Tweak.x.mrm /Users/runner/work/-os-patch/-os-patch/.theos/obj/arm64/Tweak.x.m
make[3]: *** [/Users/runner/work/-os-patch/-os-patch/.theos/obj/arm64/Tweak.x.65723d38.o] Error 1

make[2]: *** [/Users/runner/work/-os-patch/-os-patch/.theos/obj/arm64e/AnoBypass.dylib] Error 2
make[2]: *** Waiting for unfinished jobs....
make[2]: *** [/Users/runner/work/-os-patch/-os-patch/.theos/obj/arm64/AnoBypass.dylib] Error 2
make[1]: *** [internal-library-all_] Error 2
make: *** [AnoBypass.all.tweak.variables] Error 2
Error: Process completed with exit code 2.
