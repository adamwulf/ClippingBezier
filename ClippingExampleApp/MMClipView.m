//
//  MMClipView.m
//  ClippingBezier
//
//  Created by Adam Wulf on 5/23/15.
//
//

#import "MMClipView.h"
#import "UIBezierPath+SamplePaths.h"
#import <PerformanceBezier/PerformanceBezier.h>
#import <ClippingBezier/ClippingBezier.h>
#import <ClippingBezier/UIBezierPath+Clipping_Private.h>

@interface UIBezierPath (Private)

- (DKUIBezierPathClippingResult *)clipUnclosedPathToClosedPath:(UIBezierPath *)closedPath usingIntersectionPoints:(NSArray *)intersectionPoints andBeginsInside:(BOOL)beginsInside;

@end

@interface MMClipView ()

@property(nonatomic, readwrite) IBOutlet UISegmentedControl *displayTypeControl;

@end

@implementation MMClipView {
    UIBezierPath *shapePath1;
    UIBezierPath *shapePath2;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    shapePath1 = [UIBezierPath samplePath1];
    shapePath2 = [UIBezierPath samplePath2];
}

- (IBAction)changedPreviewType:(id)sender
{
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 moveToPoint:CGPointMake(1.492755, 190.738904)];
    [path1 addCurveToPoint:CGPointMake(0.375588, 189.061058) controlPoint1:CGPointMake(1.325180, 190.487234) controlPoint2:CGPointMake(0.543163, 189.648311)];
    [path1 addCurveToPoint:CGPointMake(0.375588, 186.823922) controlPoint1:CGPointMake(0.208013, 188.473806) controlPoint2:CGPointMake(-0.378500, 187.830630)];
    [path1 addCurveToPoint:CGPointMake(5.402838, 182.349637) controlPoint1:CGPointMake(1.129675, 185.817202) controlPoint2:CGPointMake(3.224363, 183.608028)];
    [path1 addCurveToPoint:CGPointMake(14.898755, 178.434642) controlPoint1:CGPointMake(7.581313, 181.091246) controlPoint2:CGPointMake(11.547255, 179.189679)];
    [path1 addCurveToPoint:CGPointMake(27.746172, 177.316074) controlPoint1:CGPointMake(18.250254, 177.679618) controlPoint2:CGPointMake(24.478458, 176.980505)];
    [path1 addCurveToPoint:CGPointMake(36.683503, 180.671791) controlPoint1:CGPointMake(31.013885, 177.651643) controlPoint2:CGPointMake(33.248216, 178.238896)];
    [path1 addCurveToPoint:CGPointMake(50.648087, 193.535331) controlPoint1:CGPointMake(40.118791, 183.104674) controlPoint2:CGPointMake(48.134464, 191.270233)];
    [path1 addCurveToPoint:CGPointMake(53.441002, 195.772467) controlPoint1:CGPointMake(52.420436, 195.132448) controlPoint2:CGPointMake(51.849041, 194.681861)];
    [path1 addCurveToPoint:CGPointMake(61.261174, 200.806030) controlPoint1:CGPointMake(55.032968, 196.863073) controlPoint2:CGPointMake(59.250272, 199.967107)];
    [path1 addCurveToPoint:CGPointMake(66.847004, 201.365321) controlPoint1:CGPointMake(63.272070, 201.644966) controlPoint2:CGPointMake(65.003679, 201.784788)];
    [path1 addCurveToPoint:CGPointMake(73.550002, 198.009616) controlPoint1:CGPointMake(68.690328, 200.945853) controlPoint2:CGPointMake(72.041827, 199.184108)];
    [path1 addCurveToPoint:CGPointMake(76.901507, 193.535331) controlPoint1:CGPointMake(75.058177, 196.835111) controlPoint2:CGPointMake(75.225754, 196.639365)];
    [path1 addCurveToPoint:CGPointMake(84.721673, 177.316074) controlPoint1:CGPointMake(78.577253, 190.431310) controlPoint2:CGPointMake(82.208044, 183.775812)];
    [path1 addCurveToPoint:CGPointMake(93.659002, 150.470414) controlPoint1:CGPointMake(87.235296, 170.856336) controlPoint2:CGPointMake(90.810230, 158.104644)];
    [path1 addCurveToPoint:CGPointMake(103.713499, 126.421167) controlPoint1:CGPointMake(96.507780, 142.836171) controlPoint2:CGPointMake(101.953967, 130.867478)];
    [path1 addCurveToPoint:CGPointMake(105.389252, 120.828327) controlPoint1:CGPointMake(105.145650, 122.802160) controlPoint2:CGPointMake(104.300018, 123.764563)];
    [path1 addCurveToPoint:CGPointMake(110.975093, 106.846206) controlPoint1:CGPointMake(106.478497, 117.892077) controlPoint2:CGPointMake(109.047977, 110.537480)];
    [path1 addCurveToPoint:CGPointMake(118.236675, 96.219796) controlPoint1:CGPointMake(112.902197, 103.154926) controlPoint2:CGPointMake(115.304106, 99.994968)];
    [path1 addCurveToPoint:CGPointMake(130.525503, 81.678392) controlPoint1:CGPointMake(121.169233, 92.444624) controlPoint2:CGPointMake(127.509153, 84.866311)];
    [path1 addCurveToPoint:CGPointMake(138.345670, 74.966976) controlPoint1:CGPointMake(133.541853, 78.490472) controlPoint2:CGPointMake(136.250982, 76.477044)];
    [path1 addCurveToPoint:CGPointMake(144.490084, 71.611266) controlPoint1:CGPointMake(140.440357, 73.456909) controlPoint2:CGPointMake(142.814343, 72.114626)];
    [path1 addCurveToPoint:CGPointMake(149.517341, 71.611266) controlPoint1:CGPointMake(146.165836, 71.107912) controlPoint2:CGPointMake(146.584771, 70.352875)];
    [path1 addCurveToPoint:CGPointMake(164.040505, 80.000539) controlPoint1:CGPointMake(152.449899, 72.869656) controlPoint2:CGPointMake(161.359299, 78.574364)];
    [path1 addCurveToPoint:CGPointMake(167.391999, 81.119107) controlPoint1:CGPointMake(166.120410, 81.106879) controlPoint2:CGPointMake(165.883830, 80.699646)];
    [path1 addCurveToPoint:CGPointMake(174.095008, 82.796960) controlPoint1:CGPointMake(168.900179, 81.538569) controlPoint2:CGPointMake(171.832737, 82.545283)];
    [path1 addCurveToPoint:CGPointMake(182.473759, 82.796960) controlPoint1:CGPointMake(176.357268, 83.048637) controlPoint2:CGPointMake(179.792553, 82.964744)];
    [path1 addCurveToPoint:CGPointMake(191.969666, 81.678392) controlPoint1:CGPointMake(185.154954, 82.629175) controlPoint2:CGPointMake(188.199238, 82.517321)];
    [path1 addCurveToPoint:CGPointMake(207.610011, 77.204113) controlPoint1:CGPointMake(195.740106, 80.839462) controlPoint2:CGPointMake(201.996246, 79.553110)];
    [path1 addCurveToPoint:CGPointMake(229.394758, 66.018419) controlPoint1:CGPointMake(213.223775, 74.855116) controlPoint2:CGPointMake(221.937669, 70.884197)];
    [path1 addCurveToPoint:CGPointMake(257.323918, 44.765602) controlPoint1:CGPointMake(236.851846, 61.152640) controlPoint2:CGPointMake(252.212881, 48.456879)];
    [path1 addCurveToPoint:CGPointMake(263.468332, 41.409891) controlPoint1:CGPointMake(261.108191, 42.032528) controlPoint2:CGPointMake(261.792591, 42.416605)];
    [path1 addCurveToPoint:CGPointMake(268.495578, 38.054184) controlPoint1:CGPointMake(265.144096, 40.403181) controlPoint2:CGPointMake(266.987421, 39.060898)];
    [path1 addCurveToPoint:CGPointMake(273.522847, 34.698476) controlPoint1:CGPointMake(270.003759, 37.047473) controlPoint2:CGPointMake(271.595731, 35.705187)];
    [path1 addCurveToPoint:CGPointMake(281.343002, 31.342769) controlPoint1:CGPointMake(275.449939, 33.691763) controlPoint2:CGPointMake(278.996951, 31.846123)];
    [path1 addCurveToPoint:CGPointMake(289.163180, 31.342769) controlPoint1:CGPointMake(283.689053, 30.839412) controlPoint2:CGPointMake(287.319856, 31.007196)];
    [path1 addCurveToPoint:CGPointMake(293.631830, 33.579905) controlPoint1:CGPointMake(291.006504, 31.678338) controlPoint2:CGPointMake(292.458816, 32.740979)];
    [path1 addCurveToPoint:CGPointMake(296.983334, 36.935616) controlPoint1:CGPointMake(294.804867, 34.418834) controlPoint2:CGPointMake(295.570218, 34.105834)];
    [path1 addCurveToPoint:CGPointMake(304.803513, 55.951293) controlPoint1:CGPointMake(298.659099, 40.291323) controlPoint2:CGPointMake(302.792605, 52.679481)];
    [path1 addCurveToPoint:CGPointMake(310.389331, 58.747720) controlPoint1:CGPointMake(306.814397, 59.223111) controlPoint2:CGPointMake(308.964942, 58.328252)];
    [path1 addCurveToPoint:CGPointMake(314.299431, 58.747720) controlPoint1:CGPointMake(311.813720, 59.167181) controlPoint2:CGPointMake(313.210186, 58.747720)];
    [path1 addCurveToPoint:CGPointMake(317.650913, 58.747720) controlPoint1:CGPointMake(315.388654, 58.747720) controlPoint2:CGPointMake(315.586367, 59.603090)];
    [path1 addCurveToPoint:CGPointMake(330.498337, 52.036301) controlPoint1:CGPointMake(320.080756, 57.741006) controlPoint2:CGPointMake(324.716989, 56.985969)];
    [path1 addCurveToPoint:CGPointMake(356.193161, 25.749920) controlPoint1:CGPointMake(336.279684, 47.086631) controlPoint2:CGPointMake(350.076693, 31.706303)];
    [path1 addCurveToPoint:CGPointMake(371.274921, 12.327088) controlPoint1:CGPointMake(362.309652, 19.793539) controlPoint2:CGPointMake(367.504481, 15.431118)];
    [path1 addCurveToPoint:CGPointMake(381.329412, 5.056386) controlPoint1:CGPointMake(375.045361, 9.223057) controlPoint2:CGPointMake(378.480634, 6.818133)];
    [path1 addCurveToPoint:CGPointMake(390.266759, 0.582109) controlPoint1:CGPointMake(384.178190, 3.294639) controlPoint2:CGPointMake(388.255851, 1.337143)];
    [path1 addCurveToPoint:CGPointMake(394.735432, 0.022824) controlPoint1:CGPointMake(392.277643, -0.172926) controlPoint2:CGPointMake(392.892084, 0.022824)];
    [path1 addCurveToPoint:CGPointMake(402.555587, 0.582109) controlPoint1:CGPointMake(396.578756, 0.022824) controlPoint2:CGPointMake(400.796054, 0.162645)];
    [path1 addCurveToPoint:CGPointMake(406.465664, 2.819247) controlPoint1:CGPointMake(404.315119, 1.001572) controlPoint2:CGPointMake(405.292627, 1.980320)];
    [path1 addCurveToPoint:CGPointMake(410.375741, 6.174956) controlPoint1:CGPointMake(407.638701, 3.658174) controlPoint2:CGPointMake(408.217212, 3.501801)];
    [path1 addCurveToPoint:CGPointMake(427.691839, 29.105629) controlPoint1:CGPointMake(413.559686, 10.117913) controlPoint2:CGPointMake(424.256565, 24.072066)];
    [path1 addCurveToPoint:CGPointMake(433.277657, 39.732039) controlPoint1:CGPointMake(431.127112, 34.139192) controlPoint2:CGPointMake(431.685708, 37.215258)];
    [path1 addCurveToPoint:CGPointMake(438.304926, 45.884170) controlPoint1:CGPointMake(434.869653, 42.248821) controlPoint2:CGPointMake(436.964305, 44.625780)];
    [path1 addCurveToPoint:CGPointMake(442.215003, 48.121310) controlPoint1:CGPointMake(439.645499, 47.142561) controlPoint2:CGPointMake(440.958174, 47.617953)];
    [path1 addCurveToPoint:CGPointMake(446.683676, 49.239878) controlPoint1:CGPointMake(443.471832, 48.624667) controlPoint2:CGPointMake(444.086273, 49.072093)];
    [path1 addCurveToPoint:CGPointMake(459.531100, 49.239878) controlPoint1:CGPointMake(449.281079, 49.407662) controlPoint2:CGPointMake(453.414585, 50.414376)];
    [path1 addCurveToPoint:CGPointMake(487.460237, 41.409891) controlPoint1:CGPointMake(465.647568, 48.065379) controlPoint2:CGPointMake(482.097848, 42.919962)];
    [path1 addCurveToPoint:CGPointMake(495.280439, 39.172755) controlPoint1:CGPointMake(492.679795, 39.940049) controlPoint2:CGPointMake(491.928910, 39.927789)];
    [path1 addCurveToPoint:CGPointMake(509.803603, 36.376329) controlPoint1:CGPointMake(498.631920, 38.417718) controlPoint2:CGPointMake(505.614205, 36.795793)];
    [path1 addCurveToPoint:CGPointMake(523.209576, 36.376329) controlPoint1:CGPointMake(513.992955, 35.956867) controlPoint2:CGPointMake(519.690511, 36.040759)];
    [path1 addCurveToPoint:CGPointMake(533.264067, 38.613468) controlPoint1:CGPointMake(526.728641, 36.711901) controlPoint2:CGPointMake(529.158507, 36.851723)];
    [path1 addCurveToPoint:CGPointMake(550.580164, 48.121310) controlPoint1:CGPointMake(537.369674, 40.375216) controlPoint2:CGPointMake(546.893516, 45.856205)];
    [path1 addCurveToPoint:CGPointMake(557.841770, 53.714157) controlPoint1:CGPointMake(554.266813, 50.386411) controlPoint2:CGPointMake(555.914654, 51.868517)];
    [path1 addCurveToPoint:CGPointMake(563.427588, 60.425572) controlPoint1:CGPointMake(559.768886, 55.559794) controlPoint2:CGPointMake(561.919431, 58.328252)];
    [path1 addCurveToPoint:CGPointMake(567.896261, 67.696271) controlPoint1:CGPointMake(564.935745, 62.522892) controlPoint2:CGPointMake(565.801562, 65.179490)];
    [path1 addCurveToPoint:CGPointMake(577.392157, 77.204113) controlPoint1:CGPointMake(569.990961, 70.213052) controlPoint2:CGPointMake(575.381249, 75.358476)];
    [path1 addCurveToPoint:CGPointMake(581.302234, 80.000539) controlPoint1:CGPointMake(579.403064, 79.049756) controlPoint2:CGPointMake(578.872415, 78.490472)];
    [path1 addCurveToPoint:CGPointMake(593.591109, 87.271239) controlPoint1:CGPointMake(583.732100, 81.510607) controlPoint2:CGPointMake(590.071997, 85.593386)];
    [path1 addCurveToPoint:CGPointMake(604.762745, 91.186233) controlPoint1:CGPointMake(597.110174, 88.949091) controlPoint2:CGPointMake(599.986851, 90.347304)];
    [path1 addCurveToPoint:CGPointMake(625.430324, 92.864085) controlPoint1:CGPointMake(609.538639, 92.025156) controlPoint2:CGPointMake(616.967781, 92.612409)];
    [path1 addCurveToPoint:CGPointMake(661.179662, 92.864085) controlPoint1:CGPointMake(633.892866, 93.115762) controlPoint2:CGPointMake(654.644236, 92.696301)];
    [path1 addCurveToPoint:CGPointMake(668.999817, 93.982654) controlPoint1:CGPointMake(666.444310, 92.999248) controlPoint2:CGPointMake(665.229377, 93.059838)];
    [path1 addCurveToPoint:CGPointMake(686.315914, 99.016217) controlPoint1:CGPointMake(672.770257, 94.905475) controlPoint2:CGPointMake(682.294099, 97.338364)];
    [path1 addCurveToPoint:CGPointMake(695.811857, 105.168348) controlPoint1:CGPointMake(690.337729, 100.694069) controlPoint2:CGPointMake(693.717157, 103.490495)];
    [path1 addCurveToPoint:CGPointMake(700.280483, 110.201910) controlPoint1:CGPointMake(697.906509, 106.846206) controlPoint2:CGPointMake(699.191284, 108.524052)];
    [path1 addCurveToPoint:CGPointMake(703.073415, 116.354042) controlPoint1:CGPointMake(701.369728, 111.879769) controlPoint2:CGPointMake(702.403128, 113.669475)];
    [path1 addCurveToPoint:CGPointMake(704.749156, 128.099026) controlPoint1:CGPointMake(703.743702, 119.038608) controlPoint2:CGPointMake(704.497828, 125.078891)];
    [path1 addCurveToPoint:CGPointMake(704.749156, 136.488293) controlPoint1:CGPointMake(705.000531, 131.119161) controlPoint2:CGPointMake(705.251906, 132.964804)];
    [path1 addCurveToPoint:CGPointMake(701.397675, 151.588982) controlPoint1:CGPointMake(704.246453, 140.011782) controlPoint2:CGPointMake(702.989624, 145.968167)];
    [path1 addCurveToPoint:CGPointMake(694.136069, 173.960370) controlPoint1:CGPointMake(699.805726, 157.209797) controlPoint2:CGPointMake(695.895601, 167.836201)];
    [path1 addCurveToPoint:CGPointMake(689.667443, 192.416763) controlPoint1:CGPointMake(692.376536, 180.084539) controlPoint2:CGPointMake(690.421521, 188.306022)];
    [path1 addCurveToPoint:CGPointMake(689.108847, 201.365321) controlPoint1:CGPointMake(688.913317, 196.527504) controlPoint2:CGPointMake(688.773680, 198.093502)];
    [path1 addCurveToPoint:CGPointMake(691.901732, 214.228860) controlPoint1:CGPointMake(689.443967, 204.637139) controlPoint2:CGPointMake(690.142200, 210.453688)];
    [path1 addCurveToPoint:CGPointMake(700.839079, 226.533123) controlPoint1:CGPointMake(693.661312, 218.004033) controlPoint2:CGPointMake(698.911963, 224.184138)];
    [path1 addCurveToPoint:CGPointMake(704.749156, 229.888839) controlPoint1:CGPointMake(702.766195, 228.882132) controlPoint2:CGPointMake(701.900378, 228.210993)];
    [path1 addCurveToPoint:CGPointMake(719.830916, 237.718829) controlPoint1:CGPointMake(707.597934, 231.566685) controlPoint2:CGPointMake(713.714449, 235.285934)];
    [path1 addCurveToPoint:CGPointMake(745.525764, 246.108109) controlPoint1:CGPointMake(725.947384, 240.151724) controlPoint2:CGPointMake(740.330911, 244.178555)];
    [path1 addCurveToPoint:CGPointMake(754.463063, 250.582381) controlPoint1:CGPointMake(750.720570, 248.037638) controlPoint2:CGPointMake(751.949452, 249.072308)];
    [path1 addCurveToPoint:CGPointMake(762.283265, 256.175210) controlPoint1:CGPointMake(756.976722, 252.092455) controlPoint2:CGPointMake(760.188566, 254.161794)];
    [path1 addCurveToPoint:CGPointMake(768.427679, 264.005199) controlPoint1:CGPointMake(764.377918, 258.188650) controlPoint2:CGPointMake(767.003267, 261.152849)];
    [path1 addCurveToPoint:CGPointMake(771.779160, 275.190906) controlPoint1:CGPointMake(769.852045, 266.857550) controlPoint2:CGPointMake(771.192665, 271.499619)];
    [path1 addCurveToPoint:CGPointMake(772.337756, 288.613723) controlPoint1:CGPointMake(772.365703, 278.882192) controlPoint2:CGPointMake(772.505340, 284.335210)];
    [path1 addCurveToPoint:CGPointMake(770.662016, 303.714412) controlPoint1:CGPointMake(772.170173, 292.892262) controlPoint2:CGPointMake(771.583678, 299.016418)];
    [path1 addCurveToPoint:CGPointMake(766.193342, 319.933681) controlPoint1:CGPointMake(769.740354, 308.412406) controlPoint2:CGPointMake(767.701500, 315.151802)];
    [path1 addCurveToPoint:CGPointMake(760.607524, 335.593660) controlPoint1:CGPointMake(764.685138, 324.715561) controlPoint2:CGPointMake(762.115682, 330.643984)];
    [path1 addCurveToPoint:CGPointMake(756.138851, 352.931485) controlPoint1:CGPointMake(759.099320, 340.543312) controlPoint2:CGPointMake(756.892930, 348.652947)];
    [path1 addCurveToPoint:CGPointMake(755.580255, 364.117167) controlPoint1:CGPointMake(755.384773, 357.209999) controlPoint2:CGPointMake(755.412672, 360.929247)];
    [path1 addCurveToPoint:CGPointMake(757.255996, 374.184293) controlPoint1:CGPointMake(755.747839, 367.305087) controlPoint2:CGPointMake(756.166750, 370.912487)];
    [path1 addCurveToPoint:CGPointMake(762.841814, 385.929264) controlPoint1:CGPointMake(758.345242, 377.456099) controlPoint2:CGPointMake(759.155166, 380.560132)];
    [path1 addCurveToPoint:CGPointMake(781.833652, 409.978523) controlPoint1:CGPointMake(766.528509, 391.298397) controlPoint2:CGPointMake(778.314587, 404.525480)];
    [path1 addCurveToPoint:CGPointMake(786.302325, 422.282761) controlPoint1:CGPointMake(785.352764, 415.431541) controlPoint2:CGPointMake(785.715830, 418.088158)];
    [path1 addCurveToPoint:CGPointMake(785.743776, 437.942739) controlPoint1:CGPointMake(786.888867, 426.477413) controlPoint2:CGPointMake(786.749183, 433.328632)];
    [path1 addCurveToPoint:CGPointMake(779.599315, 453.043428) controlPoint1:CGPointMake(784.738322, 442.556847) controlPoint2:CGPointMake(782.029181, 447.842093)];
    [path1 addCurveToPoint:CGPointMake(769.544824, 472.618389) controlPoint1:CGPointMake(777.169496, 458.244763) controlPoint2:CGPointMake(773.734223, 465.319728)];
    [path1 addCurveToPoint:CGPointMake(751.670178, 501.701186) controlPoint1:CGPointMake(765.355472, 479.917051) controlPoint2:CGPointMake(755.021659, 495.744852)];
    [path1 addCurveToPoint:CGPointMake(747.201505, 512.327602) controlPoint1:CGPointMake(748.318650, 507.657571) controlPoint2:CGPointMake(747.788000, 509.559138)];
    [path1 addCurveToPoint:CGPointMake(747.760101, 520.157617) controlPoint1:CGPointMake(746.615010, 515.096067) controlPoint2:CGPointMake(747.089767, 518.060291)];
    [path1 addCurveToPoint:CGPointMake(751.670178, 526.309760) controlPoint1:CGPointMake(748.430387, 522.254943) controlPoint2:CGPointMake(749.994437, 524.547978)];
    [path1 addCurveToPoint:CGPointMake(758.931737, 531.902564) controlPoint1:CGPointMake(753.345919, 528.071492) controlPoint2:CGPointMake(756.418126, 530.224743)];
    [path1 addCurveToPoint:CGPointMake(768.427679, 537.495417) controlPoint1:CGPointMake(761.445395, 533.580435) controlPoint2:CGPointMake(765.578901, 535.314229)];
    [path1 addCurveToPoint:CGPointMake(777.923574, 546.443962) controlPoint1:CGPointMake(771.276457, 539.676654) controlPoint2:CGPointMake(775.577547, 543.256042)];
    [path1 addCurveToPoint:CGPointMake(784.067988, 558.748249) controlPoint1:CGPointMake(780.269649, 549.631932) controlPoint2:CGPointMake(782.643623, 554.721419)];
    [path1 addCurveToPoint:CGPointMake(787.419517, 573.289647) controlPoint1:CGPointMake(785.492401, 562.775079) controlPoint2:CGPointMake(786.916766, 568.759451)];
    [path1 addCurveToPoint:CGPointMake(787.419517, 588.949626) controlPoint1:CGPointMake(787.922220, 577.819844) controlPoint2:CGPointMake(788.424971, 583.580469)];
    [path1 addCurveToPoint:CGPointMake(780.716507, 609.083878) controlPoint1:CGPointMake(786.414063, 594.318734) controlPoint2:CGPointMake(784.486947, 601.449623)];
    [path1 addCurveToPoint:CGPointMake(762.283265, 639.844546) controlPoint1:CGPointMake(776.946067, 616.718133) controlPoint2:CGPointMake(767.645654, 632.210290)];
    [path1 addCurveToPoint:CGPointMake(744.967168, 659.978797) controlPoint1:CGPointMake(756.920876, 647.478751) controlPoint2:CGPointMake(750.245765, 654.441868)];
    [path1 addCurveToPoint:CGPointMake(727.092522, 676.757307) controlPoint1:CGPointMake(739.688571, 665.515677) controlPoint2:CGPointMake(732.622495, 671.891566)];
    [path1 addCurveToPoint:CGPointMake(708.100684, 692.417286) controlPoint1:CGPointMake(721.562550, 681.623098) controlPoint2:CGPointMake(712.708995, 689.145455)];
    [path1 addCurveToPoint:CGPointMake(696.370405, 698.569430) controlPoint1:CGPointMake(703.492374, 695.689117) controlPoint2:CGPointMake(699.805726, 697.394925)];
    [path1 addCurveToPoint:CGPointMake(685.198769, 700.247301) controlPoint1:CGPointMake(692.935132, 699.743934) controlPoint2:CGPointMake(688.382667, 700.834528)];
    [path1 addCurveToPoint:CGPointMake(675.144231, 694.654447) controlPoint1:CGPointMake(682.014824, 699.660023) controlPoint2:CGPointMake(677.657889, 697.422912)];
    [path1 addCurveToPoint:CGPointMake(668.441268, 681.790870) controlPoint1:CGPointMake(672.630620, 691.885983) controlPoint2:CGPointMake(670.200801, 683.804335)];
    [path1 addCurveToPoint:CGPointMake(663.413999, 681.231580) controlPoint1:CGPointMake(666.681736, 679.777455) controlPoint2:CGPointMake(665.927610, 679.973214)];
    [path1 addCurveToPoint:CGPointMake(651.683767, 690.180175) controlPoint1:CGPointMake(660.900388, 682.489995) controlPoint2:CGPointMake(655.873119, 686.321116)];
    [path1 addCurveToPoint:CGPointMake(635.484815, 706.958685) controlPoint1:CGPointMake(647.494368, 694.039233) controlPoint2:CGPointMake(642.020241, 700.918439)];
    [path1 addCurveToPoint:CGPointMake(608.114274, 730.448678) controlPoint1:CGPointMake(628.949389, 712.998980) controlPoint2:CGPointMake(616.911936, 723.653333)];
    [path1 addCurveToPoint:CGPointMake(576.833608, 752.260751) controlPoint1:CGPointMake(599.316564, 737.243973) controlPoint2:CGPointMake(585.882645, 746.723822)];
    [path1 addCurveToPoint:CGPointMake(547.787232, 767.361439) controlPoint1:CGPointMake(567.784523, 757.797680) controlPoint2:CGPointMake(556.584941, 763.670153)];
    [path1 addCurveToPoint:CGPointMake(518.182354, 776.869275) controlPoint1:CGPointMake(538.989570, 771.052725) controlPoint2:CGPointMake(532.593781, 773.177989)];
    [path1 addCurveToPoint:CGPointMake(451.710898, 791.969964) controlPoint1:CGPointMake(503.770880, 780.560561) controlPoint2:CGPointMake(478.103979, 786.516945)];
    [path1 addCurveToPoint:CGPointMake(342.228592, 813.222796) controlPoint1:CGPointMake(425.317865, 797.422982) controlPoint2:CGPointMake(369.208168, 807.434183)];
    [path1 addCurveToPoint:CGPointMake(271.847083, 830.560596) controlPoint1:CGPointMake(315.249016, 819.011408) controlPoint2:CGPointMake(287.850505, 827.456587)];
    [path1 addCurveToPoint:CGPointMake(235.539171, 833.916338) controlPoint1:CGPointMake(255.843684, 833.664654) controlPoint2:CGPointMake(244.253065, 834.251932)];
    [path1 addCurveToPoint:CGPointMake(213.754425, 828.323484) controlPoint1:CGPointMake(226.825277, 833.580744) controlPoint2:CGPointMake(219.451981, 830.924177)];
    [path1 addCurveToPoint:CGPointMake(197.555496, 816.578488) controlPoint1:CGPointMake(208.056869, 825.722792) controlPoint2:CGPointMake(201.493520, 821.947645)];
    [path1 addCurveToPoint:CGPointMake(187.501005, 792.529254) controlPoint1:CGPointMake(193.617496, 811.209381) controlPoint2:CGPointMake(189.260537, 800.331281)];
    [path1 addCurveToPoint:CGPointMake(185.825252, 764.565038) controlPoint1:CGPointMake(185.741472, 784.727226) controlPoint2:CGPointMake(185.825252, 772.954293)];
    [path1 addCurveToPoint:CGPointMake(187.501005, 736.600772) controlPoint1:CGPointMake(185.825252, 756.175733) controlPoint2:CGPointMake(187.668576, 742.389384)];
    [path1 addCurveToPoint:CGPointMake(184.708084, 725.974356) controlPoint1:CGPointMake(187.333433, 730.812209) controlPoint2:CGPointMake(186.886563, 727.232771)];
    [path1 addCurveToPoint:CGPointMake(172.977840, 728.211517) controlPoint1:CGPointMake(182.529616, 724.715990) controlPoint2:CGPointMake(176.664489, 727.037012)];
    [path1 addCurveToPoint:CGPointMake(160.130416, 733.804370) controlPoint1:CGPointMake(169.291192, 729.386021) controlPoint2:CGPointMake(163.733285, 733.720459)];
    [path1 addCurveToPoint:CGPointMake(148.958757, 728.770807) controlPoint1:CGPointMake(156.527560, 733.888281) controlPoint2:CGPointMake(151.221016, 731.623133)];
    [path1 addCurveToPoint:CGPointMake(145.048668, 714.788699) controlPoint1:CGPointMake(146.696497, 725.918432) controlPoint2:CGPointMake(145.635186, 720.745083)];
    [path1 addCurveToPoint:CGPointMake(145.048668, 689.061594) controlPoint1:CGPointMake(144.462161, 708.832314) controlPoint2:CGPointMake(142.945538, 706.083237)];
    [path1 addCurveToPoint:CGPointMake(165.157674, 552.036815) controlPoint1:CGPointMake(148.065017, 664.648829) controlPoint2:CGPointMake(161.554805, 577.372452)];
    [path1 addCurveToPoint:CGPointMake(169.067751, 520.157617) controlPoint1:CGPointMake(168.172239, 530.838167) controlPoint2:CGPointMake(168.229881, 528.714644)];
    [path1 addCurveToPoint:CGPointMake(170.743504, 494.989802) controlPoint1:CGPointMake(169.905633, 511.600540) controlPoint2:CGPointMake(171.413802, 501.449553)];
    [path1 addCurveToPoint:CGPointMake(164.599090, 477.092662) controlPoint1:CGPointMake(170.073205, 488.530052) controlPoint2:CGPointMake(169.961490, 484.307462)];
    [path1 addCurveToPoint:CGPointMake(134.994176, 446.891285) controlPoint1:CGPointMake(159.236689, 469.877912) controlPoint2:CGPointMake(140.775512, 454.777223)];
    [path1 addCurveToPoint:CGPointMake(126.056842, 424.519922) controlPoint1:CGPointMake(129.212829, 439.005396) controlPoint2:CGPointMake(128.654245, 432.657493)];
    [path1 addCurveToPoint:CGPointMake(117.678091, 392.640698) controlPoint1:CGPointMake(123.459427, 416.382325) controlPoint2:CGPointMake(120.191714, 401.197750)];
    [path1 addCurveToPoint:CGPointMake(109.299341, 367.472884) controlPoint1:CGPointMake(115.164468, 384.083646) controlPoint2:CGPointMake(112.483262, 374.855431)];
    [path1 addCurveToPoint:CGPointMake(96.451923, 343.423625) controlPoint1:CGPointMake(106.115407, 360.090312) controlPoint2:CGPointMake(102.819771, 351.477336)];
    [path1 addCurveToPoint:CGPointMake(66.847004, 313.781538) controlPoint1:CGPointMake(90.084074, 335.369939) controlPoint2:CGPointMake(73.047281, 320.996313)];
    [path1 addCurveToPoint:CGPointMake(55.116754, 295.325157) controlPoint1:CGPointMake(60.646727, 306.566763) controlPoint2:CGPointMake(58.049318, 300.526492)];
    [path1 addCurveToPoint:CGPointMake(47.296588, 279.105888) controlPoint1:CGPointMake(52.184190, 290.123797) controlPoint2:CGPointMake(49.475061, 284.642817)];
    [path1 addCurveToPoint:CGPointMake(40.593587, 258.412371) controlPoint1:CGPointMake(45.118114, 273.568984) controlPoint2:CGPointMake(42.772063, 263.865389)];
    [path1 addCurveToPoint:CGPointMake(32.773420, 242.752392) controlPoint1:CGPointMake(38.415113, 252.959328) controlPoint2:CGPointMake(35.454621, 246.863133)];
    [path1 addCurveToPoint:CGPointMake(22.718922, 231.007420) controlPoint1:CGPointMake(30.092220, 238.641650) controlPoint2:CGPointMake(24.227096, 232.769152)];
    [path1 closePath];

    UIBezierPath *path2 = [UIBezierPath bezierPath];
    [path2 moveToPoint:CGPointMake(177.500000, 218.500000)];
    [path2 addCurveToPoint:CGPointMake(176.500000, 218.500000) controlPoint1:CGPointMake(177.350000, 218.500000) controlPoint2:CGPointMake(176.875000, 218.275000)];
    [path2 addCurveToPoint:CGPointMake(175.000000, 220.000000) controlPoint1:CGPointMake(176.125000, 218.725000) controlPoint2:CGPointMake(176.200000, 219.625000)];
    [path2 addCurveToPoint:CGPointMake(168.500000, 221.000000) controlPoint1:CGPointMake(173.800000, 220.375000) controlPoint2:CGPointMake(169.700000, 220.775000)];
    [path2 addCurveToPoint:CGPointMake(167.000000, 221.500000) controlPoint1:CGPointMake(167.463962, 221.194257) controlPoint2:CGPointMake(168.009638, 221.197109)];
    [path2 addCurveToPoint:CGPointMake(158.500000, 224.000000) controlPoint1:CGPointMake(165.500000, 221.950000) controlPoint2:CGPointMake(161.425000, 223.325000)];
    [path2 addCurveToPoint:CGPointMake(147.500000, 226.000000) controlPoint1:CGPointMake(155.575000, 224.675000) controlPoint2:CGPointMake(150.275000, 225.700000)];
    [path2 addCurveToPoint:CGPointMake(140.000000, 226.000000) controlPoint1:CGPointMake(144.725000, 226.300000) controlPoint2:CGPointMake(142.175000, 225.625000)];
    [path2 addCurveToPoint:CGPointMake(133.000000, 228.500000) controlPoint1:CGPointMake(137.825000, 226.375000) controlPoint2:CGPointMake(134.350000, 228.050000)];
    [path2 addCurveToPoint:CGPointMake(131.000000, 229.000000) controlPoint1:CGPointMake(131.696160, 228.934613) controlPoint2:CGPointMake(132.206552, 228.341881)];
    [path2 addCurveToPoint:CGPointMake(122.000000, 234.500000) controlPoint1:CGPointMake(129.350000, 229.900000) controlPoint2:CGPointMake(125.150000, 232.175000)];
    [path2 addCurveToPoint:CGPointMake(110.000000, 244.500000) controlPoint1:CGPointMake(118.850000, 236.825000) controlPoint2:CGPointMake(113.750000, 241.875000)];
    [path2 addCurveToPoint:CGPointMake(97.000000, 252.000000) controlPoint1:CGPointMake(106.250000, 247.125000) controlPoint2:CGPointMake(99.175000, 250.725000)];
    [path2 addCurveToPoint:CGPointMake(95.500000, 253.000000) controlPoint1:CGPointMake(95.963166, 252.607799) controlPoint2:CGPointMake(96.612369, 252.544940)];
    [path2 addCurveToPoint:CGPointMake(86.000000, 256.500000) controlPoint1:CGPointMake(93.850000, 253.675000) controlPoint2:CGPointMake(88.625000, 255.075000)];
    [path2 addCurveToPoint:CGPointMake(78.000000, 262.500000) controlPoint1:CGPointMake(83.375000, 257.925000) controlPoint2:CGPointMake(80.175000, 260.475000)];
    [path2 addCurveToPoint:CGPointMake(71.500000, 270.000000) controlPoint1:CGPointMake(75.825000, 264.525000) controlPoint2:CGPointMake(72.625000, 268.800000)];
    [path2 addCurveToPoint:CGPointMake(70.500000, 270.500000) controlPoint1:CGPointMake(70.990220, 270.543765) controlPoint2:CGPointMake(71.143823, 270.124437)];
    [path2 addCurveToPoint:CGPointMake(65.500000, 273.500000) controlPoint1:CGPointMake(69.600000, 271.025000) controlPoint2:CGPointMake(67.600000, 271.700000)];
    [path2 addCurveToPoint:CGPointMake(56.500000, 282.500000) controlPoint1:CGPointMake(63.400000, 275.300000) controlPoint2:CGPointMake(58.000000, 281.075000)];
    [path2 addCurveToPoint:CGPointMake(55.500000, 283.000000) controlPoint1:CGPointMake(55.959617, 283.013364) controlPoint2:CGPointMake(56.093424, 282.548998)];
    [path2 addCurveToPoint:CGPointMake(44.000000, 292.000000) controlPoint1:CGPointMake(53.625000, 284.425000) controlPoint2:CGPointMake(45.875000, 290.575000)];
    [path2 addCurveToPoint:CGPointMake(43.000000, 292.500000) controlPoint1:CGPointMake(43.406576, 292.451002) controlPoint2:CGPointMake(43.688021, 292.213325)];
    [path2 addCurveToPoint:CGPointMake(38.000000, 294.500000) controlPoint1:CGPointMake(42.100000, 292.875000) controlPoint2:CGPointMake(39.350000, 293.600000)];
    [path2 addCurveToPoint:CGPointMake(34.000000, 298.500000) controlPoint1:CGPointMake(36.650000, 295.400000) controlPoint2:CGPointMake(34.675000, 297.675000)];
    [path2 addCurveToPoint:CGPointMake(33.500000, 300.000000) controlPoint1:CGPointMake(33.332509, 299.315823) controlPoint2:CGPointMake(33.650000, 299.700000)];
    [path2 addCurveToPoint:CGPointMake(33.000000, 300.500000) controlPoint1:CGPointMake(33.350000, 300.300000) controlPoint2:CGPointMake(33.225000, 300.200000)];
    [path2 addCurveToPoint:CGPointMake(32.000000, 302.000000) controlPoint1:CGPointMake(32.775000, 300.800000) controlPoint2:CGPointMake(32.150000, 301.175000)];
    [path2 addCurveToPoint:CGPointMake(32.000000, 306.000000) controlPoint1:CGPointMake(31.850000, 302.825000) controlPoint2:CGPointMake(32.000000, 305.400000)];
    [path2 addCurveToPoint:CGPointMake(32.000000, 306.000000) controlPoint1:CGPointMake(32.000000, 306.000000) controlPoint2:CGPointMake(32.000000, 306.000000)];
    [path2 addCurveToPoint:CGPointMake(33.500000, 321.000000) controlPoint1:CGPointMake(32.225000, 308.250000) controlPoint2:CGPointMake(33.275000, 318.675000)];
    [path2 addCurveToPoint:CGPointMake(33.500000, 321.500000) controlPoint1:CGPointMake(33.532108, 321.331783) controlPoint2:CGPointMake(33.455945, 321.169591)];
    [path2 addCurveToPoint:CGPointMake(34.500000, 328.500000) controlPoint1:CGPointMake(33.650000, 322.625000) controlPoint2:CGPointMake(34.275000, 327.375000)];
    [path2 addCurveToPoint:CGPointMake(35.000000, 329.000000) controlPoint1:CGPointMake(34.592450, 328.962250) controlPoint2:CGPointMake(34.903855, 328.538504)];
    [path2 addCurveToPoint:CGPointMake(37.000000, 340.500000) controlPoint1:CGPointMake(35.375000, 330.800000) controlPoint2:CGPointMake(36.700000, 338.550000)];
    [path2 addCurveToPoint:CGPointMake(37.000000, 342.000000) controlPoint1:CGPointMake(37.152057, 341.488372) controlPoint2:CGPointMake(36.850000, 341.325000)];
    [path2 addCurveToPoint:CGPointMake(38.000000, 345.000000) controlPoint1:CGPointMake(37.150000, 342.675000) controlPoint2:CGPointMake(37.684183, 342.915605)];
    [path2 addCurveToPoint:CGPointMake(39.500000, 358.500000) controlPoint1:CGPointMake(38.375000, 347.475000) controlPoint2:CGPointMake(39.275000, 356.400000)];
    [path2 addCurveToPoint:CGPointMake(39.500000, 359.000000) controlPoint1:CGPointMake(39.535511, 358.831436) controlPoint2:CGPointMake(39.451734, 358.670180)];
    [path2 addCurveToPoint:CGPointMake(42.500000, 379.000000) controlPoint1:CGPointMake(39.950000, 362.075000) controlPoint2:CGPointMake(42.050000, 375.775000)];
    [path2 addCurveToPoint:CGPointMake(42.500000, 380.500000) controlPoint1:CGPointMake(42.638196, 379.990405) controlPoint2:CGPointMake(42.408083, 379.504233)];
    [path2 addCurveToPoint:CGPointMake(45.500000, 411.500000) controlPoint1:CGPointMake(42.950000, 385.375000) controlPoint2:CGPointMake(45.050000, 406.625000)];
    [path2 addCurveToPoint:CGPointMake(45.500000, 413.000000) controlPoint1:CGPointMake(45.591917, 412.495767) controlPoint2:CGPointMake(45.453539, 412.001080)];
    [path2 addCurveToPoint:CGPointMake(46.500000, 433.000000) controlPoint1:CGPointMake(45.650000, 416.225000) controlPoint2:CGPointMake(45.975000, 428.350000)];
    [path2 addCurveToPoint:CGPointMake(49.000000, 444.000000) controlPoint1:CGPointMake(47.025000, 437.650000) controlPoint2:CGPointMake(48.625000, 442.050000)];
    [path2 addCurveToPoint:CGPointMake(49.000000, 446.000000) controlPoint1:CGPointMake(49.251797, 445.309342) controlPoint2:CGPointMake(48.639006, 444.716465)];
    [path2 addCurveToPoint:CGPointMake(53.500000, 460.000000) controlPoint1:CGPointMake(49.675000, 448.400000) controlPoint2:CGPointMake(52.075000, 454.975000)];
    [path2 addCurveToPoint:CGPointMake(58.500000, 479.500000) controlPoint1:CGPointMake(54.925000, 465.025000) controlPoint2:CGPointMake(57.675000, 476.350000)];
    [path2 addCurveToPoint:CGPointMake(59.000000, 481.000000) controlPoint1:CGPointMake(58.767064, 480.519700) controlPoint2:CGPointMake(58.831673, 479.959434)];
    [path2 addCurveToPoint:CGPointMake(64.000000, 513.500000) controlPoint1:CGPointMake(59.825000, 486.100000) controlPoint2:CGPointMake(63.175000, 508.400000)];
    [path2 addCurveToPoint:CGPointMake(64.500000, 515.000000) controlPoint1:CGPointMake(64.168327, 514.540566) controlPoint2:CGPointMake(64.362489, 513.954915)];
    [path2 addCurveToPoint:CGPointMake(66.500000, 532.500000) controlPoint1:CGPointMake(64.875000, 517.850000) controlPoint2:CGPointMake(65.675000, 527.775000)];
    [path2 addCurveToPoint:CGPointMake(70.000000, 546.500000) controlPoint1:CGPointMake(67.325000, 537.225000) controlPoint2:CGPointMake(69.400000, 544.175000)];
    [path2 addCurveToPoint:CGPointMake(70.500000, 548.000000) controlPoint1:CGPointMake(70.263395, 547.520654) controlPoint2:CGPointMake(70.237073, 546.979225)];
    [path2 addCurveToPoint:CGPointMake(78.500000, 579.500000) controlPoint1:CGPointMake(71.775000, 552.950000) controlPoint2:CGPointMake(77.225000, 574.625000)];
    [path2 addCurveToPoint:CGPointMake(79.000000, 580.500000) controlPoint1:CGPointMake(78.688596, 580.221101) controlPoint2:CGPointMake(78.764298, 579.792893)];
    [path2 addCurveToPoint:CGPointMake(80.500000, 585.500000) controlPoint1:CGPointMake(79.300000, 581.400000) controlPoint2:CGPointMake(79.975000, 584.225000)];
    [path2 addCurveToPoint:CGPointMake(82.500000, 589.000000) controlPoint1:CGPointMake(81.025000, 586.775000) controlPoint2:CGPointMake(81.600000, 588.100000)];
    [path2 addCurveToPoint:CGPointMake(86.500000, 591.500000) controlPoint1:CGPointMake(83.400000, 589.900000) controlPoint2:CGPointMake(85.525000, 591.050000)];
    [path2 addCurveToPoint:CGPointMake(89.000000, 592.000000) controlPoint1:CGPointMake(87.475000, 591.950000) controlPoint2:CGPointMake(88.475000, 591.850000)];
    [path2 addCurveToPoint:CGPointMake(90.000000, 592.500000) controlPoint1:CGPointMake(89.525000, 592.150000) controlPoint2:CGPointMake(89.265667, 592.372290)];
    [path2 addCurveToPoint:CGPointMake(100.500000, 594.000000) controlPoint1:CGPointMake(91.725000, 592.800000) controlPoint2:CGPointMake(97.500000, 593.400000)];
    [path2 addCurveToPoint:CGPointMake(110.000000, 596.500000) controlPoint1:CGPointMake(103.500000, 594.600000) controlPoint2:CGPointMake(106.100000, 595.000000)];
    [path2 addCurveToPoint:CGPointMake(126.500000, 604.000000) controlPoint1:CGPointMake(113.900000, 598.000000) controlPoint2:CGPointMake(123.500000, 602.650000)];
    [path2 addCurveToPoint:CGPointMake(130.000000, 605.500000) controlPoint1:CGPointMake(128.814996, 605.041748) controlPoint2:CGPointMake(127.648080, 604.544533)];
    [path2 addCurveToPoint:CGPointMake(142.500000, 610.500000) controlPoint1:CGPointMake(132.400000, 606.475000) controlPoint2:CGPointMake(139.050000, 609.375000)];
    [path2 addCurveToPoint:CGPointMake(153.000000, 613.000000) controlPoint1:CGPointMake(145.950000, 611.625000) controlPoint2:CGPointMake(150.300000, 612.400000)];
    [path2 addCurveToPoint:CGPointMake(160.500000, 614.500000) controlPoint1:CGPointMake(155.700000, 613.600000) controlPoint2:CGPointMake(156.975000, 614.125000)];
    [path2 addCurveToPoint:CGPointMake(176.500000, 615.500000) controlPoint1:CGPointMake(164.025000, 614.875000) controlPoint2:CGPointMake(173.875000, 615.350000)];
    [path2 addCurveToPoint:CGPointMake(178.000000, 615.500000) controlPoint1:CGPointMake(177.498371, 615.557050) controlPoint2:CGPointMake(177.000000, 615.500000)];
    [path2 addCurveToPoint:CGPointMake(191.000000, 615.500000) controlPoint1:CGPointMake(180.175000, 615.500000) controlPoint2:CGPointMake(187.250000, 615.200000)];
    [path2 addCurveToPoint:CGPointMake(203.000000, 617.500000) controlPoint1:CGPointMake(194.750000, 615.800000) controlPoint2:CGPointMake(199.250000, 617.200000)];
    [path2 addCurveToPoint:CGPointMake(216.000000, 617.500000) controlPoint1:CGPointMake(206.750000, 617.800000) controlPoint2:CGPointMake(213.600000, 617.575000)];
    [path2 addCurveToPoint:CGPointMake(219.000000, 617.000000) controlPoint1:CGPointMake(218.026598, 617.436669) controlPoint2:CGPointMake(218.175000, 617.150000)];
    [path2 addCurveToPoint:CGPointMake(221.500000, 616.500000) controlPoint1:CGPointMake(219.825000, 616.850000) controlPoint2:CGPointMake(219.966667, 617.233333)];
    [path2 addCurveToPoint:CGPointMake(230.500000, 611.500000) controlPoint1:CGPointMake(223.225000, 615.675000) controlPoint2:CGPointMake(224.800000, 615.250000)];
    [path2 addCurveToPoint:CGPointMake(259.500000, 591.500000) controlPoint1:CGPointMake(236.200000, 607.750000) controlPoint2:CGPointMake(252.375000, 597.500000)];
    [path2 addCurveToPoint:CGPointMake(278.000000, 571.500000) controlPoint1:CGPointMake(266.625000, 585.500000) controlPoint2:CGPointMake(274.925000, 574.875000)];
    [path2 addCurveToPoint:CGPointMake(280.000000, 569.000000) controlPoint1:CGPointMake(279.437480, 569.922278) controlPoint2:CGPointMake(278.650000, 570.350000)];
    [path2 addCurveToPoint:CGPointMake(287.000000, 562.500000) controlPoint1:CGPointMake(281.350000, 567.650000) controlPoint2:CGPointMake(284.525000, 564.450000)];
    [path2 addCurveToPoint:CGPointMake(296.500000, 556.000000) controlPoint1:CGPointMake(289.475000, 560.550000) controlPoint2:CGPointMake(294.625000, 557.500000)];
    [path2 addCurveToPoint:CGPointMake(299.500000, 552.500000) controlPoint1:CGPointMake(298.375000, 554.500000) controlPoint2:CGPointMake(298.450000, 554.225000)];
    [path2 addCurveToPoint:CGPointMake(303.500000, 544.500000) controlPoint1:CGPointMake(300.550000, 550.775000) controlPoint2:CGPointMake(302.300000, 548.175000)];
    [path2 addCurveToPoint:CGPointMake(307.500000, 528.000000) controlPoint1:CGPointMake(304.700000, 540.825000) controlPoint2:CGPointMake(306.750000, 531.075000)];
    [path2 addCurveToPoint:CGPointMake(308.500000, 524.000000) controlPoint1:CGPointMake(308.151330, 525.329546) controlPoint2:CGPointMake(307.825000, 526.475000)];
    [path2 addCurveToPoint:CGPointMake(312.000000, 511.500000) controlPoint1:CGPointMake(309.175000, 521.525000) controlPoint2:CGPointMake(309.975000, 516.750000)];
    [path2 addCurveToPoint:CGPointMake(322.000000, 489.000000) controlPoint1:CGPointMake(314.025000, 506.250000) controlPoint2:CGPointMake(320.050000, 494.550000)];
    [path2 addCurveToPoint:CGPointMake(325.000000, 474.500000) controlPoint1:CGPointMake(323.950000, 483.450000) controlPoint2:CGPointMake(324.475000, 479.675000)];
    [path2 addCurveToPoint:CGPointMake(325.500000, 454.500000) controlPoint1:CGPointMake(325.525000, 469.325000) controlPoint2:CGPointMake(325.575000, 459.075000)];
    [path2 addCurveToPoint:CGPointMake(324.500000, 444.000000) controlPoint1:CGPointMake(325.425000, 449.925000) controlPoint2:CGPointMake(324.875000, 446.550000)];
    [path2 addCurveToPoint:CGPointMake(323.000000, 437.500000) controlPoint1:CGPointMake(324.125000, 441.450000) controlPoint2:CGPointMake(323.375000, 439.225000)];
    [path2 addCurveToPoint:CGPointMake(322.000000, 432.500000) controlPoint1:CGPointMake(322.625000, 435.775000) controlPoint2:CGPointMake(322.756903, 435.814009)];
    [path2 addCurveToPoint:CGPointMake(304.500000, 356.500000) controlPoint1:CGPointMake(319.225000, 420.350000) controlPoint2:CGPointMake(308.025000, 370.150000)];
    [path2 addCurveToPoint:CGPointMake(298.500000, 341.500000) controlPoint1:CGPointMake(301.806998, 346.071781) controlPoint2:CGPointMake(299.475000, 344.050000)];
    [path2 addCurveToPoint:CGPointMake(298.000000, 339.500000) controlPoint1:CGPointMake(298.009162, 340.216269) controlPoint2:CGPointMake(298.565672, 340.752559)];
    [path2 addCurveToPoint:CGPointMake(291.500000, 326.000000) controlPoint1:CGPointMake(296.950000, 337.175000) controlPoint2:CGPointMake(293.450000, 330.725000)];
    [path2 addCurveToPoint:CGPointMake(285.000000, 308.000000) controlPoint1:CGPointMake(289.550000, 321.275000) controlPoint2:CGPointMake(286.650000, 312.050000)];
    [path2 addCurveToPoint:CGPointMake(280.500000, 299.000000) controlPoint1:CGPointMake(283.350000, 303.950000) controlPoint2:CGPointMake(281.625000, 300.950000)];
    [path2 addCurveToPoint:CGPointMake(277.500000, 295.000000) controlPoint1:CGPointMake(279.375000, 297.050000) controlPoint2:CGPointMake(278.175000, 295.825000)];
    [path2 addCurveToPoint:CGPointMake(276.000000, 293.500000) controlPoint1:CGPointMake(276.825000, 294.175000) controlPoint2:CGPointMake(276.866909, 294.617349)];
    [path2 addCurveToPoint:CGPointMake(255.000000, 266.000000) controlPoint1:CGPointMake(272.625000, 289.150000) controlPoint2:CGPointMake(258.225000, 270.200000)];
    [path2 addCurveToPoint:CGPointMake(254.500000, 265.500000) controlPoint1:CGPointMake(254.712902, 265.626105) controlPoint2:CGPointMake(254.868105, 265.794484)];
    [path2 addCurveToPoint:CGPointMake(252.500000, 264.000000) controlPoint1:CGPointMake(254.125000, 265.200000) controlPoint2:CGPointMake(253.775000, 264.600000)];
    [path2 addCurveToPoint:CGPointMake(246.000000, 261.500000) controlPoint1:CGPointMake(251.225000, 263.400000) controlPoint2:CGPointMake(247.650000, 261.950000)];
    [path2 addCurveToPoint:CGPointMake(241.500000, 261.000000) controlPoint1:CGPointMake(244.350000, 261.050000) controlPoint2:CGPointMake(243.000000, 261.375000)];
    [path2 addCurveToPoint:CGPointMake(236.000000, 259.000000) controlPoint1:CGPointMake(240.000000, 260.625000) controlPoint2:CGPointMake(236.975000, 259.450000)];
    [path2 addCurveToPoint:CGPointMake(235.000000, 258.000000) controlPoint1:CGPointMake(235.143968, 258.604908) controlPoint2:CGPointMake(235.150000, 258.675000)];
    [path2 addCurveToPoint:CGPointMake(235.000000, 254.500000) controlPoint1:CGPointMake(234.850000, 257.325000) controlPoint2:CGPointMake(234.775000, 255.550000)];
    [path2 addCurveToPoint:CGPointMake(236.500000, 251.000000) controlPoint1:CGPointMake(235.225000, 253.450000) controlPoint2:CGPointMake(236.275000, 251.525000)];
    [path2 closePath];

    NSArray<UIBezierPath *> *finalShapes = [path1 intersectionWithPath:path2];

    if ([path1 isClockwise]) {
        path1 = [path1 bezierPathByReversingPath];
    }

    if ([path2 isClockwise]) {
        path2 = [path2 bezierPathByReversingPath];
    }

    BOOL clockwise1 = [path1 isClockwise];
    BOOL clockwise2 = [path2 isClockwise];

    [path1 setLineWidth:8];
    [[UIColor redColor] setStroke];
    [path1 stroke];

    [path2 setLineWidth:6];
    [[UIColor greenColor] setStroke];
    [path2 stroke];

    [[UIColor blueColor] setStroke];
    [[finalShapes firstObject] setLineWidth:2];
    [[finalShapes firstObject] stroke];
}

+ (UIColor *)randomColor
{
    static BOOL generated = NO;

    // ff the randomColor hasn't been generated yet,
    // reset the time to generate another sequence
    if (!generated) {
        generated = YES;
        srandom((int)time(NULL));
    }

    // generate a random number and divide it using the
    // maximum possible number random() can be generated
    CGFloat red = (CGFloat)random() / (CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random() / (CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random() / (CGFloat)RAND_MAX;

    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
    return color;
}


@end
