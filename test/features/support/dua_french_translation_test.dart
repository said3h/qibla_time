import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';
import 'package:qibla_time/features/support/services/dua_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const expected = <String, List<String>>{
    "hisn_morning_evening_85": [
      "Demander le pardon et la protection matin et soir",
      "Ô Allah, je Te demande le pardon et la préservation dans ce monde et dans l'au-delà. Ô Allah, je Te demande le pardon et la préservation dans ma religion, mes affaires de ce monde, ma famille et mes biens. Ô Allah, couvre mes défauts et apaise mes craintes. Ô Allah, protège-moi devant moi, derrière moi, à ma droite, à ma gauche et au-dessus de moi. Je cherche refuge dans Ta grandeur contre le fait d'être frappé par-dessous.",
      "Hisn al-Muslim 84"
    ],
    "hisn_morning_evening_86": [
      "Chercher refuge contre le mal de soi et de Satan",
      "Ô Allah, Toi qui connais l'invisible et le visible, Créateur des cieux et de la terre, Seigneur et Souverain de toute chose, j'atteste que nul n'est digne d'adoration en dehors de Toi. Je cherche refuge auprès de Toi contre le mal de mon âme, contre le mal de Satan et le polythéisme auquel il appelle, et contre le fait de commettre un mal envers moi-même ou de le causer à un musulman.",
      "Hisn al-Muslim 85"
    ],
    "hisn_morning_evening_87": [
      "Invoquer le Nom d'Allah pour être protégé",
      "Au nom d'Allah, avec le Nom duquel rien ne peut nuire sur terre ni dans le ciel. Il est Celui qui entend tout et qui sait tout.",
      "Hisn al-Muslim 86"
    ],
    "hisn_morning_evening_88": [
      "Affirmer sa satisfaction dans la foi",
      "Je suis satisfait d'Allah comme Seigneur, de l'islam comme religion et de Muhammad comme prophète.",
      "Hisn al-Muslim 87"
    ],
    "hisn_morning_evening_89": [
      "Demander secours par la miséricorde d'Allah",
      "Ô Vivant, ô Celui qui subsiste par Lui-même et soutient toute chose, c'est par Ta miséricorde que j'implore secours. Réforme pour moi toutes mes affaires et ne me laisse pas livré à moi-même, ne serait-ce que le temps d'un clin d'œil.",
      "Hisn al-Muslim 88"
    ],
    "hisn_morning_evening_79": [
      "Invocation du matin et du soir",
      "Ô Allah, par Toi nous entrons dans le matin et par Toi nous entrons dans le soir ; par Toi nous vivons et par Toi nous mourons, et c'est vers Toi que nous serons ressuscités.\n\nÔ Allah, par Toi nous entrons dans le soir et par Toi nous entrons dans le matin ; par Toi nous vivons et par Toi nous mourons, et c'est vers Toi que sera notre retour.",
      "Hisn al-Muslim 78"
    ],
    "hisn_morning_evening_80": [
      "Demander pardon matin et soir",
      "Ô Allah, Tu es mon Seigneur, nul n'est digne d'adoration en dehors de Toi. Tu m'as créé et je suis Ton serviteur. Je reste fidèle à Ton pacte et à Ta promesse autant que je le peux. Je cherche refuge auprès de Toi contre le mal de ce que j'ai fait. Je reconnais Tes bienfaits envers moi et je reconnais mon péché. Pardonne-moi, car nul autre que Toi ne pardonne les péchés.",
      "Hisn al-Muslim 79"
    ],
    "hisn_morning_evening_81": [
      "Attester l'unicité d'Allah au matin",
      "Ô Allah, en ce matin, je Te prends à témoin, ainsi que les porteurs de Ton Trône, Tes anges et toutes Tes créatures, que Tu es Allah, que nul n'est digne d'adoration en dehors de Toi, Seul et sans associé, et que Muhammad est Ton serviteur et Ton Messager.",
      "Hisn al-Muslim 80"
    ],
    "hisn_morning_evening_82": [
      "Remercier Allah pour les bienfaits du matin",
      "Ô Allah, tout bienfait qui m'est parvenu en ce matin, ou qui est parvenu à l'une de Tes créatures, vient de Toi Seul, sans associé. À Toi la louange et à Toi la gratitude.",
      "Hisn al-Muslim 81"
    ],
    "hisn_morning_evening_83": [
      "Demander la santé et la protection matin et soir",
      "Ô Allah, accorde-moi la santé dans mon corps. Ô Allah, préserve mon ouïe. Ô Allah, préserve ma vue. Nul n'est digne d'adoration en dehors de Toi. Ô Allah, je cherche refuge auprès de Toi contre la mécréance et la pauvreté, et je cherche refuge auprès de Toi contre le châtiment de la tombe. Nul n'est digne d'adoration en dehors de Toi.",
      "Hisn al-Muslim 82"
    ],
    "hisn_after_salam_73": [
      "Demander un savoir utile après le salām",
      "Ô Allah, je Te demande un savoir utile, une bonne subsistance et des œuvres acceptées.",
      "Hisn al-Muslim 73"
    ],
    "hisn_istikhara_74": [
      "Invocation de l'istikhara",
      "Ô Allah, je Te demande de choisir pour moi par Ta science, de m'accorder la capacité par Ta puissance, et je Te demande de Ton immense grâce. Tu peux et je ne peux pas, Tu sais et je ne sais pas, et Tu connais parfaitement l'invisible. Ô Allah, si Tu sais que cette affaire est un bien pour ma religion, ma subsistance et l'issue de mes affaires, décrète-la pour moi, facilite-la-moi, puis bénis-la pour moi. Et si Tu sais que cette affaire est un mal pour ma religion, ma subsistance et l'issue de mes affaires, éloigne-la de moi et éloigne-moi d'elle. Décrète pour moi le bien où qu'il se trouve, puis rends-moi satisfait de ce bien.",
      "Hisn al-Muslim 74"
    ],
    "hisn_morning_evening_75": [
      "Louange et salutations en ouverture des adhkar",
      "Louange à Allah Seul, et que la prière et la paix soient sur celui après qui il n'y a plus de prophète.",
      "Hisn al-Muslim 75a"
    ],
    "hisn_morning_evening_76": [
      "Le verset du Repose-Pied matin et soir",
      "Allah, nul n'est digne d'adoration en dehors de Lui, le Vivant, Celui qui subsiste par Lui-même et soutient toute chose. Ni somnolence ni sommeil ne Le saisissent. À Lui appartient tout ce qui est dans les cieux et sur la terre. Qui peut intercéder auprès de Lui sans Sa permission ? Il sait ce qui est devant eux et ce qui est derrière eux, et ils n'embrassent de Sa science que ce qu'Il veut. Son Repose-Pied s'étend sur les cieux et la terre, et leur préservation ne Lui pèse pas. Il est le Très-Haut, l'Immense.",
      "Hisn al-Muslim 75"
    ],
    "hisn_morning_evening_78": [
      "Invocation au début de la journée",
      "Nous voici au matin, et la royauté appartient à Allah. Louange à Allah. Nul n'est digne d'adoration en dehors d'Allah, Seul et sans associé. À Lui appartiennent la royauté et la louange, et Il est capable de toute chose. Seigneur, je Te demande le bien de cette journée et le bien de ce qui vient après elle, et je cherche refuge auprès de Toi contre le mal de cette journée et le mal de ce qui vient après elle. Seigneur, je cherche refuge auprès de Toi contre la paresse et les maux de la vieillesse. Seigneur, je cherche refuge auprès de Toi contre le châtiment du Feu et le châtiment de la tombe.",
      "Hisn al-Muslim 77"
    ],
    "hisn_salah_before_salam_64": [
      "Demander le Paradis en invoquant les Noms d'Allah",
      "Ô Allah, je Te demande, puisque la louange T'appartient et que nul n'est digne d'adoration en dehors de Toi, Seul et sans associé, Toi le Grand Donateur. Ô Créateur des cieux et de la terre, ô Détenteur de la majesté et de la générosité, ô Vivant, ô Celui qui subsiste par Lui-même et soutient toute chose, je Te demande le Paradis et je cherche refuge auprès de Toi contre le Feu.",
      "Hisn al-Muslim 64"
    ],
    "hisn_salah_before_salam_65": [
      "Invoquer l'unicité d'Allah avant le salām",
      "Ô Allah, je Te demande en attestant que Tu es Allah, que nul n'est digne d'adoration en dehors de Toi, l'Unique, Celui dont tous dépendent, qui n'a pas engendré et n'a pas été engendré, et dont nul n'est l'égal.",
      "Hisn al-Muslim 65"
    ],
    "hisn_after_salam_66": [
      "Demander pardon après le salām",
      "Je demande pardon à Allah. Je demande pardon à Allah. Je demande pardon à Allah. Ô Allah, Tu es la Paix et de Toi vient la paix. Béni sois-Tu, ô Détenteur de la majesté et de la générosité.",
      "Hisn al-Muslim 66"
    ],
    "hisn_after_salam_71": [
      "Le verset du Repose-Pied après le salām",
      "Allah, nul n'est digne d'adoration en dehors de Lui, le Vivant, Celui qui subsiste par Lui-même et soutient toute chose. Ni somnolence ni sommeil ne Le saisissent. À Lui appartient tout ce qui est dans les cieux et sur la terre. Qui peut intercéder auprès de Lui sans Sa permission ? Il sait ce qui est devant eux et ce qui est derrière eux, et ils n'embrassent de Sa science que ce qu'Il veut. Son Repose-Pied s'étend sur les cieux et la terre, et leur préservation ne Lui pèse pas. Il est le Très-Haut, l'Immense.",
      "Hisn al-Muslim 71"
    ],
    "hisn_after_salam_72": [
      "Après Fajr et Maghrib",
      "Nul n'est digne d'adoration en dehors d'Allah, Seul et sans associé. À Lui appartiennent la royauté et la louange. Il donne la vie et la mort, et Il est capable de toute chose.",
      "Hisn al-Muslim 72"
    ],
    "hisn_salah_before_salam_58": [
      "Demander le pardon de tous ses péchés avant le salām",
      "Ô Allah, pardonne-moi mes péchés passés et à venir, ce que j'ai fait en secret et ouvertement, mes excès et ce que Tu connais mieux que moi. Tu es Celui qui fait avancer et Celui qui fait reculer. Nul n'est digne d'adoration en dehors de Toi.",
      "Hisn al-Muslim 58"
    ],
    "hisn_salah_before_salam_60": [
      "Chercher protection contre les épreuves avant le salām",
      "Ô Allah, je cherche refuge auprès de Toi contre l'avarice, et je cherche refuge auprès de Toi contre la lâcheté. Je cherche refuge auprès de Toi contre le fait d'être ramené à un âge de décrépitude, et je cherche refuge auprès de Toi contre les épreuves de ce monde et le châtiment de la tombe.",
      "Hisn al-Muslim 60"
    ],
    "hisn_salah_before_salam_61": [
      "Demander le Paradis avant le salām",
      "Ô Allah, je Te demande le Paradis et je cherche refuge auprès de Toi contre le Feu.",
      "Hisn al-Muslim 61"
    ],
    "hisn_salah_before_salam_62": [
      "Demander la guidance et l'agrément avant le salām",
      "Ô Allah, par Ta connaissance de l'invisible et Ton pouvoir sur la création, fais-moi vivre tant que Tu sais que la vie est un bien pour moi, et rappelle-moi à Toi lorsque Tu sais que la mort est un bien pour moi. Ô Allah, je Te demande de Te craindre en secret et en public. Je Te demande de dire la vérité dans la satisfaction comme dans la colère. Je Te demande la modération dans la richesse comme dans la pauvreté. Je Te demande un bonheur inépuisable et une joie qui ne cesse jamais. Je Te demande l'acceptation de Ton décret une fois prononcé, et une vie paisible après la mort. Je Te demande la joie de contempler Ton Visage et le désir de Te rencontrer, sans malheur nuisible ni épreuve qui égare. Ô Allah, pare-nous de la beauté de la foi et fais de nous des guides bien guidés.",
      "Hisn al-Muslim 62"
    ],
    "hisn_salah_before_salam_63": [
      "Invoquer l'Unique pour obtenir le pardon avant le salām",
      "Ô Allah, je Te demande, ô Allah, puisque Tu es l'Un, l'Unique, Celui dont tous dépendent, qui n'a pas engendré et n'a pas été engendré, et dont nul n'est l'égal, de pardonner mes péchés. Tu es certes le Pardonneur, le Miséricordieux.",
      "Hisn al-Muslim 63"
    ],
    "hisn_salah_tashahhud_53": [
      "Prière et bénédictions sur le Prophète",
      "Ô Allah, accorde Ta grâce à Muhammad et à la famille de Muhammad, comme Tu l'as accordée à Ibrahim et à la famille d'Ibrahim. Tu es certes digne de louange et de gloire. Ô Allah, bénis Muhammad et la famille de Muhammad, comme Tu as béni Ibrahim et la famille d'Ibrahim. Tu es certes digne de louange et de gloire.",
      "Hisn al-Muslim 53"
    ],
    "hisn_salah_tashahhud_54": [
      "Prière sur le Prophète, ses épouses et sa descendance",
      "Ô Allah, accorde Ta grâce à Muhammad, à ses épouses et à sa descendance, comme Tu l'as accordée à la famille d'Ibrahim. Bénis Muhammad, ses épouses et sa descendance, comme Tu as béni la famille d'Ibrahim. Tu es certes digne de louange et de gloire.",
      "Hisn al-Muslim 54"
    ],
    "hisn_salah_before_salam_55": [
      "Demander protection avant le salām final",
      "Ô Allah, je cherche refuge auprès de Toi contre le châtiment de la tombe, contre le châtiment de l'Enfer, contre les épreuves de la vie et de la mort, et contre le mal de l'épreuve du faux Messie.",
      "Hisn al-Muslim 55"
    ],
    "hisn_salah_before_salam_56": [
      "Chercher refuge avant le salām final",
      "Ô Allah, je cherche refuge auprès de Toi contre le châtiment de la tombe, et je cherche refuge auprès de Toi contre l'épreuve du faux Messie. Je cherche refuge auprès de Toi contre les épreuves de la vie et de la mort. Ô Allah, je cherche refuge auprès de Toi contre le péché et l'endettement.",
      "Hisn al-Muslim 56"
    ],
    "hisn_salah_before_salam_57": [
      "Demander pardon avant le salām final",
      "Ô Allah, je me suis fait beaucoup de tort, et nul autre que Toi ne pardonne les péchés. Accorde-moi donc un pardon venant de Toi et fais-moi miséricorde. Tu es certes le Pardonneur, le Miséricordieux.",
      "Hisn al-Muslim 57"
    ],
    "hisn_salah_between_sujud_48": [
      "Entre les deux prosternations",
      "Seigneur, pardonne-moi. Seigneur, pardonne-moi.",
      "Hisn al-Muslim 48"
    ],
    "hisn_salah_between_sujud_49": [
      "Invocation entre les deux prosternations",
      "Ô Allah, pardonne-moi, fais-moi miséricorde, guide-moi, comble mes manques, accorde-moi le bien-être, pourvois à ma subsistance et élève mon rang.",
      "Hisn al-Muslim 49"
    ],
    "hisn_salah_tilawah_sujud_50": [
      "Lors de la prosternation de récitation",
      "Mon visage se prosterne devant Celui qui l'a créé et l'a doté de l'ouïe et de la vue par Sa force et Sa puissance. Béni soit Allah, le meilleur des créateurs.",
      "Hisn al-Muslim 50"
    ],
    "hisn_salah_tilawah_sujud_51": [
      "Invocation lors de la prosternation de récitation",
      "Ô Allah, inscris-moi auprès de Toi une récompense pour cette prosternation, décharge-moi par elle d'un péché et fais-en pour moi une réserve auprès de Toi. Accepte-la de moi comme Tu l'as acceptée de Ton serviteur Dawud.",
      "Hisn al-Muslim 51"
    ],
    "hisn_salah_tashahhud_52": [
      "Le tashahhud",
      "À Allah reviennent les salutations, les prières et les bonnes choses. Que la paix soit sur toi, ô Prophète, ainsi que la miséricorde d'Allah et Ses bénédictions. Que la paix soit sur nous et sur les serviteurs vertueux d'Allah. J'atteste que nul n'est digne d'adoration en dehors d'Allah, et j'atteste que Muhammad est Son serviteur et Son Messager.",
      "Hisn al-Muslim 52"
    ],
    "hisn_salah_rise_40": [
      "Louange en se relevant de l'inclinaison",
      "Une louange qui remplit les cieux, la terre et ce qui se trouve entre eux, ainsi que tout ce que Tu voudras au-delà. Tu es digne de louange et de gloire. La parole la plus juste qu'un serviteur puisse prononcer, et nous sommes tous Tes serviteurs, est celle-ci : ô Allah, nul ne peut retenir ce que Tu donnes, et nul ne peut donner ce que Tu retiens. La fortune de celui qui en possède ne lui est d'aucun secours auprès de Toi.",
      "Hisn al-Muslim 40"
    ],
    "hisn_salah_sujud_41": [
      "Pendant la prosternation",
      "Gloire à mon Seigneur, le Très-Haut.",
      "Hisn al-Muslim 41"
    ],
    "hisn_salah_sujud_44": [
      "Soumission pendant la prosternation",
      "Ô Allah, devant Toi je me prosterne, en Toi je crois et à Toi je me soumets. Mon visage se prosterne devant Celui qui l'a créé, l'a façonné et l'a doté de l'ouïe et de la vue. Béni soit Allah, le meilleur des créateurs.",
      "Hisn al-Muslim 44"
    ],
    "hisn_salah_sujud_46": [
      "Demander pardon pendant la prosternation",
      "Ô Allah, pardonne-moi tous mes péchés, les petits et les grands, les premiers et les derniers, les publics et les secrets.",
      "Hisn al-Muslim 46"
    ],
    "hisn_salah_sujud_47": [
      "Chercher refuge pendant la prosternation",
      "Ô Allah, je cherche refuge dans Ton agrément contre Ta colère, dans Ton pardon contre Ton châtiment, et je cherche refuge auprès de Toi contre Toi. Je ne saurais énumérer toutes les louanges qui Te reviennent. Tu es tel que Tu T'es loué Toi-même.",
      "Hisn al-Muslim 47"
    ],
    "hisn_salah_ruku_35": [
      "Glorification pendant l'inclinaison",
      "Tu es infiniment glorifié et très saint, Seigneur des anges et de l'Esprit.",
      "Hisn al-Muslim 35"
    ],
    "hisn_salah_ruku_36": [
      "Soumission pendant l'inclinaison",
      "Ô Allah, devant Toi je m'incline, en Toi je crois et à Toi je me soumets. Devant Toi s'humilient mon ouïe, ma vue, ma moelle, mes os, mes nerfs et tout ce que portent mes pieds.",
      "Hisn al-Muslim 36"
    ],
    "hisn_salah_ruku_37": [
      "Louange de la grandeur divine pendant l'inclinaison",
      "Gloire au Détenteur de la toute-puissance, de la souveraineté, de la majesté et de la grandeur.",
      "Hisn al-Muslim 37"
    ],
    "hisn_salah_rise_38": [
      "En se relevant de l'inclinaison",
      "Allah entend celui qui Le loue.",
      "Hisn al-Muslim 38"
    ],
    "hisn_salah_rise_39": [
      "Louange en se relevant de l'inclinaison",
      "Notre Seigneur, à Toi la louange, une louange abondante, bonne et bénie.",
      "Hisn al-Muslim 39"
    ],
    "hisn_salah_opening_29": [
      "Invocation d'ouverture de la prière",
      "J'ai tourné mon visage vers Celui qui a créé les cieux et la terre, en Lui vouant un culte exclusif, et je ne suis pas de ceux qui Lui associent d'autres divinités. Ma prière, mon sacrifice, ma vie et ma mort appartiennent à Allah, Seigneur des mondes, sans associé. C'est ce qui m'a été ordonné et je suis de ceux qui se soumettent à Lui. Ô Allah, Tu es le Souverain ; nul n'est digne d'adoration en dehors de Toi. Tu es mon Seigneur et je suis Ton serviteur. Je me suis fait du tort et j'ai reconnu mon péché ; pardonne-moi donc tous mes péchés, car nul autre que Toi ne pardonne les péchés. Guide-moi vers le meilleur comportement, car nul autre que Toi n'y guide, et écarte de moi le mauvais comportement, car nul autre que Toi ne l'écarte de moi. Me voici répondant à Ton appel, prêt à Te servir. Tout le bien est entre Tes mains et le mal ne T'est pas attribué. Je suis par Toi et vers Toi. Béni et exalté sois-Tu. Je Te demande pardon et me repens auprès de Toi.",
      "Hisn al-Muslim 29"
    ],
    "hisn_salah_opening_30": [
      "Invocation d'ouverture pour être guidé",
      "Ô Allah, Seigneur de Jibril, de Mikaïl et d'Israfil, Créateur des cieux et de la terre, Toi qui connais l'invisible et le visible, Tu juges entre Tes serviteurs au sujet de leurs divergences. Guide-moi, par Ta permission, vers la vérité sur laquelle ils divergent. Tu guides certes qui Tu veux vers un chemin droit.",
      "Hisn al-Muslim 30"
    ],
    "hisn_salah_opening_31": [
      "Glorification à l'ouverture de la prière",
      "Allah est le plus Grand, infiniment Grand. Allah est le plus Grand, infiniment Grand. Allah est le plus Grand, infiniment Grand. Louange à Allah en abondance, louange à Allah en abondance, louange à Allah en abondance. Gloire à Allah matin et soir. Je cherche refuge auprès d'Allah contre Satan, contre son souffle, sa voix et ses murmures.",
      "Hisn al-Muslim 31"
    ],
    "hisn_salah_ruku_33": [
      "Pendant l'inclinaison de la prière",
      "Gloire à mon Seigneur, l'Immense.",
      "Hisn al-Muslim 33"
    ],
    "hisn_salah_ruku_34": [
      "Louange et pardon pendant l'inclinaison",
      "Gloire et louange à Toi, ô Allah, notre Seigneur. Ô Allah, pardonne-moi.",
      "Hisn al-Muslim 34"
    ],
    "hisn_social_209": [
      "En entrant au marché",
      "Nul n'est digne d'adoration en dehors d'Allah, Seul et sans associé. À Lui appartiennent la royauté et la louange. Il donne la vie et la mort, et Il est Vivant et ne meurt pas. Le bien est dans Sa main et Il est capable de toute chose.",
      "Hisn al-Muslim 209"
    ],
    "hisn_food_181": [
      "Après avoir terminé un repas",
      "Louange à Allah, une louange abondante, bonne et bénie, dont nous ne pouvons nous acquitter pleinement, que nous ne délaissons pas et dont nous ne pouvons nous passer, ô notre Seigneur.",
      "Hisn al-Muslim 181"
    ],
    "hisn_food_182": [
      "Invocation de l'invité pour son hôte",
      "Ô Allah, bénis pour eux ce que Tu leur as accordé, pardonne-leur et fais-leur miséricorde.",
      "Hisn al-Muslim 182"
    ],
    "hisn_food_183": [
      "Pour la personne qui nous a nourris ou donné à boire",
      "Ô Allah, nourris celui qui m'a nourri et donne à boire à celui qui m'a donné à boire.",
      "Hisn al-Muslim 183"
    ],
    "hisn_rain_170": [
      "En cas de fortes pluies",
      "Ô Allah, fais tomber la pluie autour de nous et non sur nous. Ô Allah, sur les hauteurs, les collines, le fond des vallées et les endroits où poussent les arbres.",
      "Hisn al-Muslim 170"
    ],
    "hisn_social_202": [
      "En remboursant une dette",
      "Qu'Allah bénisse ta famille et tes biens. La contrepartie d'un prêt n'est autre que les remerciements et le remboursement.",
      "Hisn al-Muslim 202"
    ],
    "hisn_social_204": [
      "Répondre à une invocation de bénédiction",
      "Et qu'Allah te bénisse aussi.",
      "Hisn al-Muslim 204"
    ],
    "hisn_social_205": [
      "Contre les mauvais présages",
      "Ô Allah, il n'y a de présage que ce que Tu décrètes, de bien que Ton bien, et nul n'est digne d'adoration en dehors de Toi.",
      "Hisn al-Muslim 205"
    ],
    "hisn_travel_206": [
      "En montant dans un moyen de transport",
      "Au nom d'Allah, et louange à Allah. Gloire à Celui qui a mis ceci à notre service, alors que nous n'aurions pas pu le maîtriser par nous-mêmes. C'est vers notre Seigneur que nous retournerons. Louange à Allah, louange à Allah, louange à Allah. Allah est le plus Grand, Allah est le plus Grand, Allah est le plus Grand. Gloire à Toi, ô Allah ! Je me suis fait du tort ; pardonne-moi, car nul autre que Toi ne pardonne les péchés.",
      "Hisn al-Muslim 206"
    ],
    "hisn_travel_208": [
      "En entrant dans une ville",
      "Ô Allah, Seigneur des sept cieux et de ce qu'ils couvrent, Seigneur des sept terres et de ce qu'elles portent, Seigneur des démons et de ceux qu'ils égarent, Seigneur des vents et de ce qu'ils dispersent, je Te demande le bien de cette ville, le bien de ses habitants et le bien de ce qui s'y trouve. Je cherche refuge auprès de Toi contre son mal, le mal de ses habitants et le mal de ce qui s'y trouve.",
      "Hisn al-Muslim 208"
    ],
    "hisn_protection_126": [
      "Face à des personnes hostiles",
      "Ô Allah, nous Te plaçons face à eux et cherchons refuge auprès de Toi contre leur mal.",
      "Hisn al-Muslim 126"
    ],
    "hisn_stress_193": [
      "En cas de colère",
      "Je cherche refuge auprès d'Allah contre Satan, le banni.",
      "Hisn al-Muslim 193"
    ],
    "hisn_social_194": [
      "En voyant une personne éprouvée",
      "Louange à Allah qui m'a préservé de ce par quoi Il t'a éprouvé et m'a largement favorisé par rapport à beaucoup de Ses créatures.",
      "Hisn al-Muslim 194"
    ],
    "hisn_gathering_195": [
      "Demander pardon lors d'une assemblée",
      "Seigneur, pardonne-moi et accepte mon repentir. Tu es certes Celui qui accueille le repentir, le Pardonneur.",
      "Hisn al-Muslim 195"
    ],
    "hisn_social_197": [
      "Répondre à une invocation de pardon",
      "Et à toi aussi.",
      "Hisn al-Muslim 197"
    ],
    "hisn_after_prayer_27": [
      "Invocation d'ouverture pour la purification",
      "Ô Allah, éloigne-moi de mes péchés comme Tu as éloigné l'Orient de l'Occident. Ô Allah, purifie-moi de mes péchés comme on purifie un vêtement blanc de la saleté. Ô Allah, lave-moi de mes péchés avec la neige, l'eau et la grêle.",
      "Hisn al-Muslim 27"
    ],
    "hisn_after_prayer_28": [
      "Louange à l'ouverture de la prière",
      "Gloire et louange à Toi, ô Allah. Béni soit Ton Nom, exaltée soit Ta majesté, et nul n'est digne d'adoration en dehors de Toi.",
      "Hisn al-Muslim 28"
    ],
    "hisn_stress_120": [
      "Face à l'inquiétude et à la tristesse",
      "Ô Allah, je suis Ton serviteur, fils de Ton serviteur et de Ta servante. Mon toupet est dans Ta main. Ton jugement s'accomplit sur moi et Ton décret à mon égard est juste. Je Te demande, par tout Nom qui T'appartient, par lequel Tu T'es nommé, que Tu as révélé dans Ton Livre, que Tu as enseigné à l'une de Tes créatures ou que Tu T'es réservé dans la connaissance de l'invisible auprès de Toi, de faire du Coran le printemps de mon cœur, la lumière de ma poitrine, la dissipation de ma tristesse et la disparition de mon inquiétude.",
      "Hisn al-Muslim 120"
    ],
    "hisn_stress_122": [
      "Dans la détresse",
      "Nul n'est digne d'adoration en dehors d'Allah, l'Immense, le Longanime. Nul n'est digne d'adoration en dehors d'Allah, Seigneur du Trône immense. Nul n'est digne d'adoration en dehors d'Allah, Seigneur des cieux, Seigneur de la terre et Seigneur du noble Trône.",
      "Hisn al-Muslim 122"
    ],
    "hisn_stress_125": [
      "Allah est mon Seigneur",
      "Allah, Allah est mon Seigneur. Je ne Lui associe rien.",
      "Hisn al-Muslim 125"
    ],
    "hisn_waking_up_2": [
      "Dhikr au réveil",
      "Nul n'est digne d'adoration en dehors d'Allah, Seul et sans associé. À Lui appartiennent la royauté et la louange, et Il est capable de toute chose. Gloire à Allah, louange à Allah, nul n'est digne d'adoration en dehors d'Allah et Allah est le plus Grand. Il n'y a de force ni de puissance qu'en Allah, le Très-Haut, l'Immense. Seigneur, pardonne-moi.",
      "Hisn al-Muslim 2"
    ],
    "hisn_clothing_5": [
      "En mettant un vêtement",
      "Louange à Allah qui m'a vêtu de ce vêtement et me l'a accordé sans force ni puissance de ma part.",
      "Hisn al-Muslim 5"
    ],
    "hisn_clothing_6": [
      "En mettant un vêtement neuf",
      "Ô Allah, à Toi la louange ; c'est Toi qui m'as vêtu de ce vêtement. Je Te demande son bien et le bien pour lequel il a été fait. Je cherche refuge auprès de Toi contre son mal et le mal pour lequel il a été fait.",
      "Hisn al-Muslim 6"
    ],
    "hisn_home_16": [
      "En sortant de chez soi",
      "Au nom d'Allah, je place ma confiance en Allah. Il n'y a de force ni de puissance qu'en Allah.",
      "Hisn al-Muslim 16"
    ],
    "hisn_home_17": [
      "Protection en sortant de chez soi",
      "Ô Allah, je cherche refuge auprès de Toi contre le fait de m'égarer ou d'être égaré, de commettre une faute ou d'y être entraîné, de commettre une injustice ou d'en subir une, d'agir avec ignorance ou de subir l'ignorance d'autrui.",
      "Hisn al-Muslim 17"
    ],
  };
  final entries =
      (jsonDecode(File('assets/data/duas_multilang.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();

  for (final item in expected.entries) {
    test('${item.key} resolves the reviewed French title and full body', () {
      final raw = entries.singleWhere((e) => e['id'] == item.key);
      final model = DuaMultilenguaje.fromJson(raw);
      for (final locale in ['fr']) {
        final dua = model.getDua(locale);
        expect(dua.id, item.key);
        expect(dua.title, item.value[0]);
        expect(dua.translation, item.value[1]);
        expect(dua.translation, isNot(model.getDua('en').translation));
        expect(dua.reference, item.value[2]);
        const specificCounts = {
          'hisn_salah_ruku_33': 3,
          'hisn_salah_sujud_41': 3,
          'hisn_after_salam_72': 10,
          'hisn_morning_evening_81': 4,
          'hisn_morning_evening_83': 3,
          'hisn_morning_evening_87': 3,
          'hisn_morning_evening_88': 3,
        };
        final expectedCount = specificCounts[item.key] ?? 1;
        expect(dua.count, expectedCount);
        expect(dua.arabicText, raw['arabicText']);
        expect(dua.transliteration, raw['transliteration']);
      }
    });
  }
  test('French regional locale resolves through the app service', () async {
    final service = DuaService(initialLanguageCode: 'fr-FR');
    final localized = await service.loadAll();
    for (final item in expected.entries) {
      final dua = localized.singleWhere((e) => e.id == item.key);
      expect(dua.title, item.value[0]);
      expect(dua.translation, item.value[1]);
    }
  });

  test('Ayat al-Kursi keeps identical French text in both contexts', () {
    final after = entries.singleWhere((e) => e['id'] == 'hisn_after_salam_71');
    final morning =
        entries.singleWhere((e) => e['id'] == 'hisn_morning_evening_76');
    expect(after['arabicText'], morning['arabicText']);
    expect(after['translations']['fr']['translation'],
        morning['translations']['fr']['translation']);
    expect(after['reference'], 'Hisn al-Muslim 71');
    expect(morning['reference'], 'Hisn al-Muslim 75');
  });

  test('French translation batch retains all entries and IDs', () {
    expect(entries, hasLength(200));
    expect(entries.map((e) => e['id']).toSet(), hasLength(200));
  });
}
