extends RefCounted

const MON_PHAI = [
 {"ten":"Thanh Vân Kiếm Tông", "vu_khi":"kiem", "ho_tro":"an", "mau":120.0, "tuyet_ky":"Vạn Kiếm Quy Tông", "mo":"Kiếm quét diện rộng · Tuyệt kỹ gây sát thương quanh người.", "hoi":12.0},
 {"ten":"Cửu Tiêu Lôi Tông", "vu_khi":"loi", "ho_tro":"phu", "mau":100.0, "tuyet_ky":"Thiên Lôi Giáng Thế", "mo":"Sét truyền mục tiêu · Tuyệt kỹ đánh tối đa năm yêu vật.", "hoi":14.0},
 {"ten":"Liên Hoa Đan Tông", "vu_khi":"cham", "ho_tro":"ngoc", "mau":110.0, "tuyet_ky":"Liên Hoa Hộ Thể", "mo":"Phi châm làm chậm · Tuyệt kỹ hồi máu và hộ thân.", "hoi":16.0}
]
const CANH_GIOI = ["Luyện Khí", "Trúc Cơ", "Kim Đan", "Nguyên Anh", "Hóa Thần"]
const MOC_TU_VI = [0, 8, 22, 45, 75]
const TRUM = ["Hắc Lang Yêu Vương", "Cổ Mộc Chân Quân", "Ma Tôn Vô Tướng"]
const TEN_NGAN = {"kiem":"Thanh Vân","cham":"Băng Phách","luan":"Hỏa Luân","no":"Xuyên Vân","an":"Xích Hỏa Ấn","phu":"Tật Phong","ngoc":"Thiên Nhãn","loi":"Tử Điện","bang":"Hàn Nguyệt"}
const DO = {
 "loi": {"ten":"Tử Điện Châu", "dau":"ϟ", "loai":"Tầm xa", "sat":17.0, "nhip":1.12, "tam":295.0, "mo":"Sét truyền tối đa ba mục tiêu; mỗi lần truyền còn 75% sức mạnh."},
 "bang": {"ten":"Hàn Nguyệt Luân", "dau":"☾", "loai":"Cận chiến", "sat":10.0, "nhip":1.2, "tam":150.0, "mo":"Vòng băng đánh quanh người, làm chậm 35% trong 1,5 giây."},
	"kiem": {"ten":"Thanh Vân Kiếm", "dau":"╱", "loai":"Cận chiến", "sat":19.0, "nhip":0.72, "tam":136.0, "mo":"Quét một cung, đánh trúng nhiều mục tiêu."},
	"cham": {"ten":"Băng Phách Châm", "dau":"✦", "loai":"Tầm xa", "sat":10.0, "nhip":0.48, "tam":350.0, "mo":"Phi châm bám địch, làm chậm 35% trong 1,5 giây."},
	"luan": {"ten":"Hỏa Luân", "dau":"☉", "loai":"Cận chiến", "sat":13.0, "nhip":0.95, "tam":124.0, "mo":"Vành lửa đánh quanh người."},
	"no": {"ten":"Xuyên Vân Nỏ", "dau":"➶", "loai":"Tầm xa", "sat":26.0, "nhip":1.05, "tam":425.0, "mo":"Tên sấm xuyên qua tối đa ba địch."},
	"an": {"ten":"Xích Hỏa Ấn", "dau":"◆", "loai":"Hỗ trợ", "mo":"Vũ khí liền kề tăng 35% sát thương mỗi bậc."},
	"phu": {"ten":"Tật Phong Phù", "dau":"◇", "loai":"Hỗ trợ", "mo":"Vũ khí liền kề hồi đòn nhanh hơn 18% mỗi bậc."},
	"ngoc": {"ten":"Thiên Nhãn Ngọc", "dau":"❖", "loai":"Hỗ trợ", "mo":"Vũ khí liền kề tăng 28% tầm đánh mỗi bậc."}
}
const DI_VAT = {
	"mat": ["Thiên Nhãn", "Đạn của địch chậm hơn 22%."],
	"dep": ["Vân Hành Ngoa", "Lướt hồi nhanh hơn 30%."],
	"coi": ["Dưỡng Hồn Ngọc", "Hồi 3 máu sau mỗi 5 địch hạ gục."],
	"von": ["Tụ Bảo Bồn", "Nhặt thêm 1 linh thạch từ mỗi địch."],
	"vo": ["Ảnh Độn Phù", "Khi lướt, gây 12 sát thương cho địch lướt qua."]
}
const TANG = ["Thanh Vân Sơn", "U Minh Cổ Điện", "Đài Độ Kiếp"]
const DIA_DIEM = ["Linh Tuyền", "Trúc Lâm", "Cấm Địa", "Linh Bảo Các", "Cổ Đàn", "Trấn Yêu Điện"]
const NOI = [[0,1],[0,2],[1,3],[2,4],[3,5],[4,5]]
const VI_TRI_BAN_DO = [Vector2(105,245),Vector2(280,150),Vector2(280,340),Vector2(475,150),Vector2(475,340),Vector2(660,245)]
const O_LIEN_KE = [[1,3],[0,2,4],[1,5],[0,4],[1,3,5],[2,4]]
const MO_O = [0,1,3,4,2,5]
