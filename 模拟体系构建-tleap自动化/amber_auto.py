import pexpect
import re
import argparse
from sltcap_module import run_sltcap
from Bio.PDB import PDBParser

# 定义原子质量表
atomic_masses = {"H": 1.00784, "C": 12.0107, "N": 14.0067, "O": 15.999, "S": 32.065, "CA": 40.078}



# 解析命令行参数
#parser = argparse.ArgumentParser(description="Process a PDB file.")
#parser.add_argument("pdb_file", help="Path to the PDB file")
#args = parser.parse_args()

# 使用传入的 PDB 文件路径
pdb_file = "eps.pdb"

# 加载 PDB 文件
#pdb_file = args.pdb_file
parser = PDBParser()
structure = parser.get_structure("protein", pdb_file)

# 计算总质量
total_mass = 0.0
for atom in structure.get_atoms():
    element = atom.element  # 获取原子元素
    total_mass += atomic_masses.get(element, 0)
    
total_mass_kda = total_mass / 1000
print(f"Total molecular weight: {total_mass_kda:.2f} kDa")
# 启动 tleap
child = pexpect.spawn('tleap', encoding='utf-8')

# 如果你想观察输出内容（调试时很有用）
child.logfile = open("tleap_log.txt", "w")

# 定义需要依次输入的 tleap 命令
tleap_commands = [
    "source leaprc.protein.ff14SB",
    "source leaprc.water.tip3p",
    "loadamberparams frcmod.ions1lm_126_tip3p",
    "Mpro = loadpdb eps.pdb",
    "set default PBRadii mbondi2",
    "saveamberparm Mpro dry_complex.prmtop dry_complex.inpcrd",
    "charge Mpro",
    # "addIons Mpro Cl- Na+ 18",
    "solvatebox Mpro TIP3PBOX 12.0",
    # "addIonsRand Mpro Na+ 20 Cl- 20",
    "saveamberparm Mpro complex_solv.prmtop complex_solv.inpcrd",
    "quit"
]

# 顺序发送每条命令
for index, cmd in enumerate(tleap_commands): 
    child.expect_exact(">")  # 等待上一个命令完成
    
    
    if cmd == "charge Mpro":
        print(f"\n>>> Sending command: {cmd}")
    if cmd == "solvatebox Mpro TIP3PBOX 12.0":
        print(f"\n>>> Sending command: {cmd}")

    if cmd == "solvatebox Mpro TIP3PBOX 12.0":
        output = child.before
        output = str(output)
        #matches = re.findall(r'\s+([^\s]+)$', output, flags=re.MULTILINE)
        matches = re.findall(r'Total (?:unperturbed|perturbed) charge:\s*(-?\d+\.\d+)', output)
        #print("下面是输出")
        #print(output)
        #print("下面是输出结束")
        #print(matches)
        charge_1 = int(float(matches[0]))
        charge_2 = int(float(matches[1]))
        if charge_1 >= 0:
            
            child.sendline(f"addIons Mpro Cl- {matches[0][1:]}")
            child.expect_exact(">")
            #print(f"addIons Mpro Cl- {matches[0][1:]}")
        if charge_1 <= 0:
            
            child.sendline(f"addIons Mpro Na+ {matches[0][1:]}")
            child.expect_exact(">")
            #print(f"addIons Mpro Na+ {matches[0][1:]}")
    
    if cmd == "saveamberparm Mpro complex_solv.prmtop complex_solv.inpcrd":
        output = child.before
        for line in output.splitlines():
            if "Total vdw box size" in line:
                matches = re.findall(r'(\d+\.\d+)', line)
                x_length = matches[0]
                y_length = matches[1]
                z_length = matches[2]
                # 调用 run_sltcap 函数并获取返回的结果文本
                result_text, anions, cations = run_sltcap(
                input_mass=str(total_mass_kda),
                input_conc="150",
                input_charge="0",
                box_x=str(float(x_length) / 10),
                box_y=str(float(y_length) / 10),
                box_z=str(float(z_length) / 10),
                save_to_file=False) # 不保存结果到文件，只获取结果
                print("下面是输入信息汇总")
                print(f"Total vdw box size Matches: {matches}")
                print(f"total_mass_kda: {total_mass_kda}")
                print(f"x_length: {str(float(x_length) / 10)}")
                print(f"y_length: {str(float(y_length) / 10)}")
                print(f"z_length: {str(float(z_length) / 10)}")
                print(f"Result Text: {result_text}")
                print(f"Anions: {anions}")
                print(f"Cations: {cations}")
                print("上面是输入信息汇总")

        child.sendline(f"addIonsRand Mpro Na+ {str(cations)} Cl- {str(anions)}")
        child.expect_exact(">")
        print(output)  # 打印刚刚的输出内容（也就是写入 logfile 的内容）

    
    if cmd == "quit":
        child.sendline("quit")
        child.expect(pexpect.EOF)  # 等待程序退出
        final_output = child.before
        print("🔚 quit 后的输出如下：")
        print(final_output)
        break  # 退出循环
    else:
        child.sendline(cmd)
   
print() 
# 关闭会话
child.close()

