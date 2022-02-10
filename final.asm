.data
	falsenumber: .word 28

	espace: .asciiz " "
	slash: .asciiz "|"
	tiret: .asciiz " __________________ \n"

	#pour Thomas :
	#filename: .asciiz "/Users/thomasrio/1FO/MIPS/GhaliounRio_Sudoku/grille.txt" 	  #filename for input
	#pour Maï :
	filename: .asciiz "/home/polytech/ProjetMIPS/test.txt"
	#pour Autre
	#filename : .asciiz "/grille.txt"
	buffer: .space 1024
	buffer1: .asciiz "\n"
	buffer2: .word 82 #tableau sur lequel nous travaillons
	val: .space 128
	bufferugig1: .asciiz "\n"
	Avant: .asciiz "Sudoku avant résolution: "
	Apres: .asciiz "\n\nSudoku après résolution: "
	erreur: .asciiz "Erreur dans l'ouverture du fichier, fin du programme"
	nb: .word 81 #size of the sudoku
.text

main:

	jal ouvreGrille		# on appelle la fonction qui lit le fichier texte

	# init $t1 = 1 -> avant
	ori $t1, $zero, 1
	jal affiche_etat

	#transformation du buffer de char en buffer2 de int
	# adresse de buffer = $a1
	li $t2, 81
	ori $t1,$zero,0         	# le i de notre boucle for(i=0;i<81;i++)
	la $a3,buffer2			# adresse de notre buffer2 (de int)

	sub $sp $sp 4 			# empiler
	sw $ra, 0($sp) 		# sauver l'adresse de retour
	bcl_tr_char_2_int:
		beq $t1,$t2,srt_tr_char_2_int      # si i = 81 on sort de la boucle
		lb $t3,0($a1)           	# char = 1 octet donc lb le premier octet de l'adresse mémoire
		andi $t3,$t3,0x0F		# transformation d'un char à un int
		sw $t3,0($a3)	       	# on enregistre la valeur en int dans le buffer2
		addi $a1,$a1,1			# adresse buffer char
		addi $a3,$a3,4			# adresse buffer2 word
		addi $t1,$t1,1			# i++
		j bcl_tr_char_2_int
	srt_tr_char_2_int:
	la $a1, buffer2		# $a1 = adresse buffer2
	lw $ra, 0($sp)
	add $sp,$sp,4 			# dépiler

	jal afficheGrille # on appelle la fonction afficheGrille avant la résolution

	ori $a1, $zero, 0
	# init $t1 = 0 -> apres
	ori $t1, $zero, 0

	jal affiche_etat

	#Initialisation
	ori $t1,$zero,0   	# initialisation $t1 à 0 -> position à 0
	ori $t2,$t2,81    	# nb case, position max
	la $a0,buffer2    	# initialisation, chargement de l'adresse du sudoku dans $a0

	jal solvesudoku   	# on appelle la fonction solvesudoku

	la $a1, buffer2	# $a1 = adresse buffer2
	jal afficheGrille	# on appelle la fonction afficheGrille après la résolution

	li $v0,16			# system call for close file
	move $a0,$s6		# file descriptor to close
	syscall

	ori $v0, $zero, 10 	# exit() fin du programme
	syscall

affiche_etat:

	beq $t1, 0, apres_solve
	# Afficher string "Sudoku avant résolution:"
	li $v0,4
	la $a0,Avant
	syscall
	jr $ra

	apres_solve:
	# Afficher string "Sudoku après résolution:"
	li $v0,4
	la $a0,Apres
	syscall
	jr $ra

ouvreGrille:
	# Open file for reading

	li $v0,13 			# appel systeme ouverture de fichier
	la $a0, filename 		# nom du chemin du fichier
	li $a1, 0 			# flag pour la lecture
	li $a2, 0 			# le mode est ignoré
	syscall
	move $s0,$v0 			# sauvegarde de la description du fichier

	# si $v0 < 0 -> afficher erreur et terminer le programme

	bltz $v0, file_corrupted
	j si_file_okay

	file_corrupted:
		la $a0, erreur
		li $v0, 4
		syscall

		ori $v0, $zero, 10 	# exit() fin du programme
		syscall

	si_file_okay:
		# reading from file just opened
		li $v0,14 			# appel systeme pour la lecture du fichier
		move $a0,$s0			# copie de la description
		la $a1, buffer 		# adresse du buffer
		li $a2, 1024			# longueur du buffer codé en dur
		syscall
		jr $ra


# @brief résout le sudoku avec une technique récursive appelé backtracking
# @param int grille[9][9] - grille du sudoku actuel
# @param int position - indice de 0 à 81 des cases de la grille
solvesudoku:

	# Initialisation
	la $a0,buffer2    		# initialisation, chargement de l'adresse du sudoku dans $a0

	bne $t1,$t2,Next		# if position == 81 -> return 1
	ori $t0,$zero,1		# return 1
	#jr $ra

	Next:
		# array 9*9 same as array 81
		# Initialisation des valeurs
		ori $t3,$zero,9
		divu $t1,$t3			# i=position/9 et j=position%9
		mflo $t4        		# i
		mfhi $t5        		# j
		ori $t8,$t5,0 			# save j in $t8
		mult $t4,$t3   		# i i*9 = nombre de cases par ligne
		mflo $t4       		# i
		add $t5,$t4,$t5 		# pour trouver la case i*9 +j
		ori  $t3,$zero,4 		# ce sont des int nous devons multiplier par 4 car un int = 4 octets
		mult $t5,$t3
		mflo $t5 				# additionnons $t5 à la mémoire

		add $a0,$a0,$t5
		lw   $t6,0($a0) 		# loading grille[i][j]

		#ori $t9,$a0,0 #saving adress grille[i][j]

		beq $t6,$zero,Next2 	# if grille[i][j] == 0 on passe à la boucle for sinon récursivité
		
		j recursivite 			# return solvesudoku (grille, position +1)
		lw $a0, 8($sp)				# on rend les valeurs après le retour de fonction
	lw $t1, 4($sp)
	lw $ra, 0($sp)
	add $sp,$sp,12				# on remet la pile à sa place initiale
	jr $ra					# on sort de la fonction
	recursivite:

	# 4*81 + 8 (position + ra)
	sub $sp,$sp,12				# on fait de la place dans la pile pour sauvegarder
	sw  $ra,0($sp)				# on sauvegarde l'adresse de retour avant l'appel de fonction
	sw $t1, 4($sp)				# on sauvegarde la position
	sw $a0, 8($sp)				# on sauvegarde l'adresse du tableau

	addi $t1,$t1,1
	jal solvesudoku

	#lw $a0, 8($sp)				# on rend les valeurs après le retour de fonction
	#lw $t1, 4($sp)
	#lw $ra, 0($sp)
	#add $sp,$sp,12				# on remet la pile à sa place initiale
	#jr $ra					# on sort de la fonction

	#for de la fonction solvesudoku
	Next2:
		# Initialisation
		ori $t7,$zero,0 		# k = 0

		#Boucle for
		boucle_solve:
		addi $t7,$t7,1 		# k++

		beq  $t7,10,Next3  		# k <= 9
		la $s1, falsenumber
		lw $s1, 0($s1)
		beq $t7, $s1,boucle_solve
		sub $sp $sp 4 			# empiler
		sw $ra, 0($sp) 		# sauver l'adresse de retour
		jal absentsurligne		# appel de fonction
		lw $ra, 0($sp)			# reprendre adresse de retour
		add $sp,$sp, 4 		# dépiler
		beq $t0,0,boucle_solve 		# si faux on continue la boucle for

		sub $sp,$sp,4			# empiler
		sw $ra,0($sp)
		jal absentSurColonne	# appel de fonction
		lw $ra, 0($sp)
		add $sp,$sp,4 			# dépiler
		beq $t0,0,boucle_solve 	# test si absentcolonne vraie

		sub $sp,$sp,4			# empiler
		sw $ra,0($sp)
		jal absentsurbloc		# appel de fonction
		lw $ra, 0($sp)
		add $sp,$sp,4 			# dépiler
		beq $t0,0,boucle_solve

		sw $t7,0($a0) 			# changement de valeur de grille[i][j]
		
		
		sub $sp,$sp,12				# on fait de la place dans la pile pour sauvegarder
		sw  $ra,0($sp)				# on sauvegarde l'adresse de retour avant l'appel de fonction
		sw $t1, 4($sp)				# on sauvegarde la position
		sw $a0, 8($sp)				# on sauvegarde l'adresse du tableau

		addi $t1,$t1,1
		jal solvesudoku

		#lw $a0, 8($sp)				# on rend les valeurs après le retour de fonction
		#lw $t1, 4($sp)
		#lw $ra, 0($sp)
		#add $sp,$sp,12				# on remet la pile à sa place initiale

		#jr $ra

		beq $t0,0,boucle_solve 	# si le retour de la fct vaut zero, on reprend la boucle
		ori $t0,$zero,1 		# return 1
		lw $a0, 8($sp)				# on rend les valeurs après le retour de fonction
		lw $t1, 4($sp)
		lw $ra, 0($sp)
		add $sp,$sp,12				# on remet la pile à sa place initiale

		jr $ra



		#j boucle_solve

	Next3:
		ori $t6,$zero,0    		# grille[i][j] = 0
		sw $t6,0($a0)			# --
		ori $t0,$zero,0    		# return 0
		lw $a0, 8($sp)				# on rend les valeurs après le retour de fonction
		lw $t1, 4($sp)
		lw $ra, 0($sp)
		add $sp,$sp,12				# on remet la pile à sa place initiale

		jr $ra

# @brief vérifie si le chiffre k n'est pas déjà présent
# sur la ligne i
# @param int k - le chiffre à tester
# @param int grille[9][9] - grille du sudoku actuel
# @param int i - ligne sur laquelle on teste
absentsurligne:
	ori $s0,$zero,0 			# for j=0,j<9,j++
	boucle2:
		beq $s0,9,FIN
		#k = $t7, j= $s0, 9*i=$t4
		la $a1, buffer2
		addu $s2,$t4,$s0 		# ligne i*9 + j
		mult $s2,$t3 			# *4 pour obtenir la bonne case mémoire
		mflo $s2
		addu $a1,$a1,$s2 		# changement d'adresse mémoire
		lw   $s1, 0($a1) 		# grille[i][j]

		bne $s1,$t7,suiteligne 	# si la case n'est pas égale a k on continue la boucle
		ori $t0,$zero,0 		# return 0
		jr $ra

	suiteligne:
		addi $s0,$s0,1
		j boucle2

	FIN:
		ori $t0,$zero,1
		jr $ra

# @brief vérifie si le chiffre k n'est pas déjà présent
# sur le bloc dont est compris la position i,j
# @param int k - le chiffre à tester
# @param int grille[9][9] - grille du sudoku actuel
# @param int i - ligne sur laquelle on teste
# @param int j - colonne sur laquelle on teste
absentsurbloc:
	#k=$t7,9*i=$t4,j=$t8
	ori $s0,$zero,9 		# $s0 = 9
	div $t4,$s0			# $s1 = 9*i/9 = i = nbr ligne
	mflo $s1

	ori $s2,$zero,3		# $s2 = 3
	div $s1,$s2			# $s2 = i%3
	mfhi $s2
	sub $s2,$s1,$s2 		# $s2 = sous_i = i - (i%3)

	ori $s1,$zero,3		# $s1 = 3
	div $t8,$s1			# $s1 = j%3
	mfhi $s1
	sub $s1,$t8,$s1		# $s1 = j - (j%3) = sous_j

	ori $s5,$s1,0 			# sauvegarde de sous_j

	ori $s3,$zero,3
	add $s3,$s3,$s2 		# $s3 = sous_i+3
	add $s4,$s3,$s1 		# $s4 = sous_j+3

	boucle_i:				# for(i=sous_i;i<sous_i+3;i++)
		beq $s2,$s3,FINI

		boucle_j: 			# for(i=sous_j;j<sous_j+3;j++)
			beq 	$s1,$s4,FINJ
			mult $s2,$s0 		# $s6 = sous_i*9
			mflo $s6

			addu $s6,$s6,$s1 	# $s6 = i*9 + j

			mult $s6,$t3		# $s6 = (i*9 + j) * 4 = adresse
			mflo $s6

			la 	$a2,buffer2	# $a2 = tab(0)
			addu $a2,$a2,$s6	# $a2 = tab(i*9 + j)
			lw 	$s7,0($a2)	# $s7 = valeur de grille(i,j)

			addi $s1,$s1,1	# j++


			bne $s7,$t7,boucle_j# on revient à la boucle j si condition fausse
			ori $t0,$zero,0
			jr $ra

		FINJ:
			addi $s1,$s5,0 	# on remet j à sous_j
			addi $s2,$s2,1 	# on incrémente sous_i
			j boucle_i

		FINI:
			ori $t0,$zero,1
			jr $ra

# @brief vérifie si le chiffre k n'est pas déjà présent
# sur la colone j
# @param int k - le chiffre à tester
# @param int grille[9][9] - grille du sudoku actuel
# @param int j - colonne sur laquelle on teste
absentSurColonne:
	ori $s0, $zero, 0	# i = 0
	bcl_abs_colonne:
		beq $s0, 9, FIN_abs_colonne
		#k = $t7, j= $t8, 9*i=$t4
		la $a1, buffer2
		ori $s3, $zero, 9   #*9
		mult $s3, $s0 #i*9
		mflo $s3
		add $s2,$t8,$s3	# ligne i*9 + j
		mult $s2,$t3 		# *4 pour obtenir la bonne case mémoire
		mflo $s2
		addu $a1,$a1,$s2 	# changement d'adresse mémoire
		lw   $s1, 0($a1) 	# grille[i][j]

		bne $s1,$t7,suitecol# si la case n'est pas égale a k on continue la boucle
		ori $t0,$zero,0 	# return 0
		jr $ra
	suitecol:
		addi $s0,$s0,1		# i++
		j bcl_abs_colonne

	FIN_abs_colonne:
		ori $t0,$zero,1	# return 0
		jr $ra


# @brief fonction qui affiche la grille du sudoku
# @param grille[9][9]
# @details successions de print en focntion de la
# position par rapport à la grille
afficheGrille:
	la $a0, buffer1
	li $v0, 4
	syscall
	syscall
	syscall
	syscall
	syscall

	add $a2, $a1, 324			# a2 = 81 = adr(buffer2) + 81 ints (81 * 4bytes)
	ori $t1, $zero, 0 			# i = 0

	ori $t2, $zero, 0
	la $a0, slash				# affiche tiret vertical
	li $v0, 4
	syscall

	bcl_aff_grille:
		beq $a1, $a2, fin_affiche	# si adr actuelle = fin du tab
		beq $t1, 9, Carriage_rtn		# si i == 9 alors -> Carriage_rtn

		la $a0, espace				# affiche espace
		li $v0, 4
		syscall

		ori $t3, $zero, 3
		div $t1, $t3
		mfhi $t3

		bne $t3, 0, scd_espace
		la $a0, espace				# affiche espace
		li $v0, 4
		syscall

		scd_espace:
		lw $a0, 0($a1)				# affiche l'entier actuel
		li $v0, 1
		syscall

		addi $a1, $a1, 4			# changement à tab(i)
		addi $t1, $t1, 1 			# i++
		j bcl_aff_grille

	Carriage_rtn:
		la $a0, espace			# affiche espace
		li $v0, 4
		syscall

		la $a0, slash			# affiche tiret vertical
		li $v0, 4
		syscall

		la $a0, buffer1		# effectue le retour à la ligne
		li $v0, 4
		syscall



		ori $t1, $zero, 0		# remet le compteur de lignes à 0
		addi $t2, $t2, 1

		beq $t2, 3, scd_cr
		la $a0, slash			# affiche tiret vertical
		li $v0, 4
		syscall
		j bcl_aff_grille

	scd_cr:
		la $a0, buffer1		# effectue le retour à la ligne
		li $v0, 4
		syscall
		la $a0, slash			# affiche tiret vertical
		li $v0, 4
		syscall
		ori $t2, $zero, 0
		j bcl_aff_grille

	fin_affiche:
		la $a0, espace			# affiche espace
		li $v0, 4
		syscall

		la $a0, slash			# affiche tiret vertical
		li $v0, 4
		syscall

		jr $ra				# retour de la fonction

#fin :)